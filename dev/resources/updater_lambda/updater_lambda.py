import os, json
import boto3

cf    = boto3.client("cloudfront")
elbv2 = boto3.client("elbv2")
r53 = boto3.client("route53")


def _get_alb_dns_by_name(alb_name: str) -> str:
    resp = elbv2.describe_load_balancers(Names=[alb_name])
    lbs = resp.get("LoadBalancers", [])
    if not lbs:
        raise RuntimeError(f"ALB not found by name: {alb_name}")
    return lbs[0]["DNSName"]

def _find_distribution_id_by_alias(alias: str) -> str:
    paginator = cf.get_paginator("list_distributions")

    for page in paginator.paginate():
        items = page.get("DistributionList", {}).get("Items", [])
        for d in items:
            aliases = d.get("Aliases", {}).get("Items", [])
            if alias in aliases:
                return d["Id"]

    raise RuntimeError(f"CloudFront distribution with alias '{alias}' not found")

def _update_cloudfront_origin(distribution_id: str, origin_id: str, new_domain: str):
    dist = cf.get_distribution_config(Id=distribution_id)
    config = dist["DistributionConfig"]
    etag = dist["ETag"]

    origins = config.get("Origins", {}).get("Items", [])
    found = False

    for o in origins:
        if o.get("Id") == origin_id:
            # CloudFront expects the origin DomainName without protocol
            o["DomainName"] = new_domain
            found = True
            break

    if not found:
        raise RuntimeError(f"Origin Id '{origin_id}' not found in distribution {distribution_id}")

    cf.update_distribution(
        Id=distribution_id,
        IfMatch=etag,
        DistributionConfig=config
    )

def _update_route53_record(hosted_zone_id: str, record_names: str, target_zone_id: str, target_dns: str):
    for record_name in record_names:
        r53.change_resource_record_sets(
            HostedZoneId=hosted_zone_id,
            ChangeBatch={
                "Comment": "Update ALIAS target",
                "Changes": [
                    {
                        "Action": "UPSERT",
                        "ResourceRecordSet": {
                            "Name": record_name,
                            "Type": "A",
                            "AliasTarget": {
                                "HostedZoneId": target_zone_id,
                                "DNSName": "dualstack." + target_dns,
                                "EvaluateTargetHealth": False
                            }
                        }
                    }
                ]
            }
        )


def handler(event, context):
    print("Event data:", json.dumps(event) )

    if event["detail"]["eventName"] == "CreateDistributionWithTags":
        print("CASE B: Created CloudFront Distribution. Updating Route 53...")
        hosted_zone_id = os.environ["HOSTED_ZONE_ID_PUB"]
        record_names   = os.environ["DISTRIBUTION_ALIAS"].split(",")
        target_zone_id = os.environ["CFRONT_ZONE_ID"]
        target_dns     = event["detail"]["responseElements"]["distribution"]["domainName"]

        _update_route53_record(hosted_zone_id, record_names, target_zone_id, target_dns)
        print(f"R53 records {record_names} updated!")

    elif event["detail"]["eventName"] == "CreateLoadBalancer":
        if event["detail"]["requestParameters"]["name"] == "dev-dp-001-app-alb":
            print("CASE A: Created App ALB. Updating CloudFront Distribution origin...")
            distribution_alias = os.environ["DISTRIBUTION_ALIAS"]
            origin_id          = os.environ["ORIGIN_ID"]
            alb_name           = os.environ["ALB_NAME"]

            alb_dns         = _get_alb_dns_by_name(alb_name)
            distribution_id = _find_distribution_id_by_alias(distribution_alias)
            
            _update_cloudfront_origin(distribution_id, origin_id, alb_dns)
            print(f"Distribution {distribution_id} updated!")

        elif event["detail"]["requestParameters"]["name"] == "dev-dp-001-admin-alb":
            print("CASE C: Created Admin ALB. Updating Route 53...")
            hosted_zone_id = os.environ["HOSTED_ZONE_ID_PUB"]
            record_names   = os.environ["ALB_RECORD_NAMES"].split(",")
            target_zone_id = event["detail"]["responseElements"]["loadBalancers"][0]["canonicalHostedZoneId"]
            target_dns     = event["detail"]["responseElements"]["loadBalancers"][0]["dNSName"]

            _update_route53_record(hosted_zone_id, record_names, target_zone_id, target_dns)
            print(f"R53 records {record_names} updated!")

    else:
        print("Received event did not match any action criteria! Skipping...")