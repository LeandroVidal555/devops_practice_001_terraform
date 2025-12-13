import os, json
import boto3

cf    = boto3.client("cloudfront")
elbv2 = boto3.client("elbv2")


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

def _update_cloudfront_origin(distribution_id: str, origin_id: str, new_domain: str) -> bool:
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
    return True


def handler(event, context):
    print("Event data:", json.dumps(event) )

    # TODO: introduce if statement to detect case (A, B, C, see my notes) 
    #       and target to update, based on event data

    # CASE COVERED: A

    distribution_alias = os.environ["DISTRIBUTION_ALIAS"]
    origin_id          = os.environ.get("ORIGIN_ID")
    alb_name           = os.environ["ALB_NAME"]

    alb_dns         = _get_alb_dns_by_name(alb_name)
    distribution_id = _find_distribution_id_by_alias(distribution_alias)
    
    _update_cloudfront_origin(distribution_id, origin_id, alb_dns)

    return {
        "updated":         True,
        "distribution_id": distribution_id,
        "origin_id":       origin_id,
        "alb_name":        alb_name,
        "alb_dns":         alb_dns,
    }
