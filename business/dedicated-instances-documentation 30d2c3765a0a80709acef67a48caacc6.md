# dedicated-instances-documentation

# Dedicated Instances

| Date | Author | Version | Comment |
| --- | --- | --- | --- |
| 12/17/2025 | Simon Coombes | 0.1 | Initial Document |
| 01/24/2026 | Simon Coombes | 0.2 | Drafted - Ready for Review |
| 02/19/2026 | @Sudarshan Sampath  | 0.3 | Added MSK and OpenSearch Serverless sections; filled in supported regions; added non-PrivateLink security model; resolved Information Exchange TODO |

---

## Who Should Read This?

This page is intended for customers evaluating, securing, and implementing an Unstructured Dedicated Instance. Depending on your role, you may want to focus on different sections of this documentation.

### Security, Risk, and Compliance Teams

If you are responsible for reviewing Unstructured from a security, risk, or compliance perspective, this documentation will help you understand how Dedicated Instances support stricter security requirements.

You may want to focus on:
- [Concepts & Architecture](about:blank#concepts--architecture) — to understand the single-tenant and private networking model.
- [Security Model](about:blank#security-model) — including encryption, network isolation, and threat boundaries.
- [Security FAQ](about:blank#security-faq) — for answers to common security and compliance review questions.

### Platform, Infrastructure, and Cloud Engineering Teams

If you are responsible for designing, deploying, or operating cloud infrastructure, this documentation provides the technical details required to integrate a Dedicated Instance into your environment.

You may want to focus on:
- [Concepts & Architecture](about:blank#concepts--architecture) — to understand traffic flow, DNS resolution, and private connectivity.
- [Requirements & Limitations](about:blank#requirements--limitations) — including supported cloud providers and known constraints.
- [Preparing for a Dedicated Instance](about:blank#preparing-for-a-dedicated-instance) — to understand timelines and required inputs.
- [AWS PrivateLink](about:blank#aws-privatelink-specific-information) or [Azure Private Link](about:blank#azure-private-link-specific-information) sections — for detailed, service-specific configuration requirements.

### Decision Makers and Technical Evaluators

If you are evaluating whether a Dedicated Instance is the right deployment model for your organization, this documentation provides a high-level view of the benefits and tradeoffs.

You may want to focus on:
- [Overview and Benefits](about:blank#overview) — to understand when a Dedicated Instance is appropriate.
- [Architecture](about:blank#concepts--architecture) — to see how private networking is implemented.
- [Security FAQ](about:blank#security-faq) — for assurance around data usage, isolation, and access controls.

---

## Overview

A Dedicated Instance is a privately isolated deployment hosted by Unstructured intended for customers who need increased network isolation, data isolation, and stricter compliance controls.

> **Note:** A Dedicated Instance is a **regional service** — it is deployed into a single cloud provider region. This has implications for data residency, failover design, and latency. Cross-region PrivateLink is supported but incurs additional data transfer costs and is not advised.
> 

When combined with capabilities like AWS or Azure PrivateLink, customers can ensure private IP connectivity between their VPC/VNet and Unstructured without traversing the public Internet. In addition, the use of network filtering ensures that ingress/egress network traffic to the public web can be completely blocked or limited to specific IP addresses or CIDR ranges.

**Benefits:**

- **Eliminates public exposure:** Traffic between your VPC/VNet and Unstructured can avoid the public Internet and instead traverse cloud-provider private networking.
- **Stronger network isolation for sensitive workloads:** Helps customers meet internal security requirements and compliance where “private network access” is preferred or mandated.
- **Simpler enterprise network integration:** Works well with existing private connectivity patterns (VPC/VNet isolation, VPN/DirectConnect/ExpressRoute to corporate on-prem networks).
- **Clearer control and auditability:** Private endpoints + private DNS make it easier to manage where traffic flows and enforce network-level access patterns.

---

## Concepts & Architecture

Private connectivity routes traffic through cloud-provider private networking backplane instead of the public Internet.

**AWS private connectivity** uses AWS PrivateLink interface endpoints to connect customer VPCs to the Unstructured VPC without traversing the public internet, and vice versa.

**Azure private connectivity** uses Azure Private Link so access occurs through a private IP and traffic stays on the Microsoft backbone.

There are two directions of connectivity:

| Direction | Description |
| --- | --- |
| **Customer → Unstructured** | Customer applications access the Unstructured UI and API via a private endpoint in the customer’s VPC/VNet. |
| **Unstructured → Customer** | Unstructured accesses customer data sources (S3 buckets, databases, vector stores, etc.) via private endpoints created in the Unstructured VPC/VNet. |

Both directions can be established independently. Customers with strict egress controls should configure both.

---

## Requirements & Limitations

Dedicated Instances rely on cloud-provider private networking features and therefore require certain baseline infrastructure components.

### Supported Cloud Providers and Regions

| Cloud Provider | Availability |
| --- | --- |
| AWS | General Availability |
| Azure | General Availability |
| GCP | Not currently supported |

**AWS Supported Regions:**

| Region Name | Region Code |
| --- | --- |
| US East (N. Virginia) | `us-east-1` |
| US East (Ohio) | `us-east-2` |
| US West (Oregon) | `us-west-2` |
| Europe (Ireland) | `eu-west-1` |
| Europe (Stockholm) | `eu-north-1` |
| Europe (Frankfurt) | `eu-central-1` |
| Asia Pacific (Sydney) | `ap-southeast-2` |
| Asia Pacific (Mumbai) | `ap-south-1` |
| Asia Pacific (Seoul) | `ap-northeast-2` |

> If your required region is not listed above, contact your Unstructured account representative.
> 

**Azure Supported Regions:** Contact your Unstructured account representative for the current list of supported Azure regions.

### Prerequisites

**AWS Requirements:**
- VPC with private subnets
- Network Load Balancer (for connections into Customer environment)
- IAM permissions to create VPC endpoints, security groups, and Route 53 records

**Azure Requirements:**
- Virtual Network with subnets configured for private endpoints
- Private endpoint network policies disabled on target subnets
- Standard Load Balancer (for connections into Customer environment)

### DNS Requirements

Private connectivity requires DNS configuration to route traffic through private endpoints:
- AWS: Route 53 Private Hosted Zone (and on-premise DNS forwarding if needed)
- Azure: Azure Private DNS Zone linked to your VNet
- CNAME records pointing to the private endpoint

The DNS name will be provided to you by Unstructured, in the form `<company>.privatelink.unstructuredapp.io`.

### Known Limitations

| Limitation | Notes |
| --- | --- |
| Cross-Region PrivateLink | Supported but incurs additional data transfer costs; not advised |
| Cross-Cloud PrivateLink | Not supported (e.g., AWS to Azure) |
| VPC Peering | Not supported as an alternative to PrivateLink |

---

## Security Model

### Encryption

All connections to Dedicated Instances use TLS 1.2 or higher for encryption in transit.

| Layer | Encryption |
| --- | --- |
| API Endpoints | TLS 1.2+ with certificate validation |
| Cloud Storage Connections (S3, Blob Storage) | TLS encryption with bucket/container policies enforcing encryption |
| Internal Service Mesh | mTLS between microservices |

### Security Without PrivateLink (Internet-Facing Mode)

Customers who deploy a Dedicated Instance without PrivateLink access the platform over the public internet via HTTPS. The following controls apply:

- **TLS 1.2+** for all traffic in transit.
- **AWS WAF** (Web Application Firewall) provides DDoS protection, rate limiting, and optional geo-blocking for ITAR compliance.
- **IP Allowlisting** — Access to the platform can be restricted to specific source IP addresses or CIDR ranges. Submit a support ticket with your IP list to enable this.
- **No data egress change** — Unstructured can still access customer data sources via PrivateLink even if the customer accesses the platform UI/API over the internet. The two directions are configured independently.

### Security With PrivateLink

When PrivateLink is enabled, traffic between your environment and Unstructured flows entirely over cloud-provider private networking. Service endpoints resolve to private IP addresses, and no inbound access from the public internet is permitted.

### What PrivateLink Does and Does Not Protect

| Protected | Not Protected |
| --- | --- |
| Network traffic from public internet exposure | Application-layer vulnerabilities |
| Data in-transit between VPCs/VNets | Misconfigured IAM/RBAC policies |
| DNS resolution of service endpoints | Compromised credentials |

### Optional: Customer-Managed Encryption Keys

By default, Unstructured manages encryption keys using the cloud provider’s key management service (AWS KMS or Azure Key Vault). Customers with strict key custody requirements can optionally bring their own KMS Customer Managed Keys (CMK). Contact your account representative to enable this.

### Shared Responsibility Model

**Customer → Unstructured (Accessing Unstructured UI and API)**

| Responsibility | Customer | Unstructured |
| --- | --- | --- |
| VPC/VNet Configuration | ✔ |  |
| VPC Endpoint / Private Endpoint Creation | ✔ |  |
| DNS Configuration | ✔ |  |
| Security Group / NSG Rules | ✔ |  |
| VPC Endpoint Service Creation |  | ✔ |
| Endpoint Connection Approval |  | ✔ |
| Load Balancer and Target Configuration |  | ✔ |
| Platform Security & Certificate Management |  | ✔ |

**Unstructured → Customer (Accessing Customer Data Sources)**

| Responsibility | Customer | Unstructured |
| --- | --- | --- |
| VPC Endpoint Service Creation | ✔ |  |
| Load Balancer and Target Configuration | ✔ |  |
| Endpoint Connection Approval | ✔ |  |
| Security Group / NSG Rules | ✔ |  |
| Bucket/Container Policies | ✔ |  |
| VPC Endpoint / Private Endpoint Creation |  | ✔ |
| DNS Configuration |  | ✔ |

> Responsibilities apply only to the party operating the corresponding cloud resources.
> 

### Network Access Controls

**Default Configuration:**

| Traffic Direction | Default State |
| --- | --- |
| Public Ingress | **Blocked** — All inbound traffic from the public internet is denied. Access is only available via PrivateLink. |
| Public Egress | **Blocked** — All outbound traffic to the public internet is denied. The platform can only communicate with resources accessible via PrivateLink or within the Unstructured VPC/VNet. |

This default configuration provides maximum network isolation and is recommended for customers with strict compliance requirements.

**Optional: Enabling Public Egress**

Some integrations require outbound internet access. Examples include:
- Third-party AI/ML APIs (e.g., OpenAI, Anthropic, Gemini) not hosted in your cloud environment.
- External webhooks or callback URLs.
- Public SaaS services without PrivateLink support (see [connector coverage](about:blank#aws-privatelink-connector-coverage) below).

If your use case requires public egress, Unstructured can enable outbound internet access with the following options:

| Option | Description |
| --- | --- |
| Full Egress | All outbound internet traffic is permitted (not recommended) |
| Specific IPs/CIDRs | Outbound traffic is permitted only to specified IP addresses or CIDR ranges |

To request egress configuration changes, log a support ticket and provide:
- Application/use-case requirements for the access change.
- List of IPs or CIDR ranges to allowlist.
- Expected traffic patterns (e.g., VLM API calls, SSO integration).

**Optional: Enabling Public Ingress**

In rare cases, customers may require public ingress (e.g., for users who cannot access via PrivateLink). Access will be restricted to specified IP addresses or CIDR ranges, and all traffic remains encrypted via TLS 1.2+.

To request ingress configuration changes, log a support ticket and provide:
- Application/use-case requirements.
- List of source IP addresses or CIDR ranges to allowlist.
- Expected access patterns.

> **Note:** Enabling public ingress or egress reduces the network isolation benefits of a Dedicated Instance. Unstructured recommends using PrivateLink for all connectivity where possible.
> 

---

## Security FAQ

**Is my Dedicated Instance single-tenant?**
Yes. Each Dedicated Instance is logically isolated and single-tenant. Your instance is not shared with other customers at the application or network level.

**Does traffic ever traverse the public internet?**
By default, Dedicated Instances are configured with strict network controls to block public ingress and egress. When PrivateLink is enabled, traffic between your environment and Unstructured flows entirely over cloud-provider private networking. Public ingress/egress can be enabled on request for specific use cases — see [Network Access Controls](about:blank#network-access-controls).

**Is data encrypted?**
Yes.
- **In transit:** All traffic uses TLS 1.2 or higher.
- **Internally:** Mutual TLS (mTLS) is used between platform services.
- **Cloud storage:** Encryption policies are enforced at the storage layer.
- **At rest:** Optional customer-managed KMS keys are available on request.

**Can Unstructured access my data?**
Unstructured personnel do not access customer data as part of normal operations. Access to customer data sources is explicitly configured, limited to the minimum permissions required, and governed by customer-controlled IAM, RBAC, and resource policies. Any exceptional access (e.g., for troubleshooting) follows strict internal controls and auditing.

**Is customer data used to train models?**
No. Customer data processed within a Dedicated Instance is not used to train models.

**How is access to the platform controlled?**
- Customers manage user access to the Unstructured UI and APIs.
- Network access is restricted using private endpoints, security groups, and firewall rules.
- DNS resolution is private and scoped to customer networks.

**What does PrivateLink protect against?**
PrivateLink helps protect against exposure to the public internet, unintended inbound network access, and DNS-based traffic interception. PrivateLink does not protect against application-layer vulnerabilities, misconfigured IAM or RBAC policies, or compromised credentials.

**How long is customer data retained?**
Unstructured does not store customer data long-term. Customer artifacts are used ephemerally during workflow execution and removed upon completion or failure. Transformed data is written to the configured destination. The only data that persists in the Unstructured platform is connector and workflow configuration metadata, connector keys (stored in a secret store), and workflow execution telemetry (which does not contain file data).

**What compliance standards does Unstructured support?**
Unstructured maintains industry-standard security and compliance programs including HIPAA compliance architecture, ITAR-readiness with geo-blocking via AWS WAF, and SOC 2 controls. Detailed compliance artifacts are available from our trust center.

---

## Preparing for a Dedicated Instance

Once you’ve decided to proceed with a Dedicated Instance, the next steps involve provisioning the environment and establishing private connectivity. The deployment process is conducted remotely and can typically be completed within the following timeframes:

| Cloud Provider | Without PrivateLink | With PrivateLink |
| --- | --- | --- |
| AWS | 2–3 Days | 4–5 Days |
| Azure | 2–3 Days | 4–5 Days |

> Times are subject to Customer infrastructure team availability. More complex integrations (multiple connectors, custom models, etc.) will extend the deployment timeline.
> 

### Information Required for Provisioning

Before deployment can begin, please provide the following:

| Information Required | Description |
| --- | --- |
| Name of Administrator | Primary administrator of the account (others can be added after) |
| Admin Email Address | Email address of the primary admin |
| Cloud Provider | AWS or Azure |
| Cloud Region | Please see [list of supported regions](about:blank#supported-cloud-providers-and-regions) |
| Desired URL | Without PrivateLink: `<companyname>.unstructuredapp.io` / With PrivateLink: `<companyname>.privatelink.unstructuredapp.io` |
| VLM Provider | Anthropic, Bedrock, OpenAI, Azure OpenAI, etc. |
| VLM Models | e.g., Claude Sonnet 4.5, GPT-4o, Gemini 2.0 Flash |
| Embedding Models | e.g., Titan, Granite (ensure you select correct dimensions) |

> **Do not send API keys by email or any collaboration tool.** Unstructured has a secure method of capturing these.
> 

### Information Exchange

All PrivateLink configuration data exchanges between Customer and Unstructured must be conducted via support tickets. This ensures a documented audit trail of all shared information, including Account IDs, VPC Endpoint Service Names, IAM Role ARNs, Service Principal IDs, and other sensitive configuration details.

To initiate a PrivateLink configuration, log a ticket via the [Unstructured Support Portal](https://support.unstructured.io/) with the subject line: **“PrivateLink Configuration Request — [Your Company Name]”**. A technical enablement engineer will respond to guide you through the exchange.

---

## AWS PrivateLink — Connector Coverage

Not all Unstructured platform connectors can be accessed via AWS PrivateLink. The table below summarizes the coverage and configuration approach for each connector in a Dedicated Instance context.

| Connector | PrivateLink Supported | Approach | Configuration Section |
| --- | --- | --- | --- |
| **Customer → Unstructured (UI/API)** | ✅ | Interface VPC Endpoint | [Link](about:blank#connections-into-unstructured-vpc-aws) |
| **AWS S3** | ✅ | Gateway Endpoint | [Link](about:blank#aws-s3-gateway-endpoint) |
| **AWS Bedrock** (VLM) | ✅ | Interface VPC Endpoint (Unstructured side) | [Link](about:blank#aws-bedrock) |
| **AWS OpenSearch Service** | ✅ | Interface VPC Endpoint | [Link](about:blank#aws-managed-services-with-native-privatelink) |
| **AWS OpenSearch Serverless** | ✅ | VPC Endpoint + Data Access Policy | [Link](about:blank#aws-opensearch-serverless) |
| **AWS MSK (Kafka)** | ✅ | Multi-VPC Connectivity (MSK native) | [Link](about:blank#aws-msk-kafka) |
| **AWS RDS / PostgreSQL** | ✅ | NLB-backed Endpoint Service | [Link](about:blank#customer-managed-services-aws-or-aws-services-with-nlb) |
| **Databricks on AWS** | ✅ | Databricks PrivateLink | [Link](about:blank#aws-databricks) |
| **Elasticsearch (self-hosted on AWS)** | ✅ | NLB-backed Endpoint Service | [Link](about:blank#customer-managed-services-aws-or-aws-services-with-nlb) |
| **MongoDB (self-hosted on AWS)** | ✅ | NLB-backed Endpoint Service | [Link](about:blank#customer-managed-services-aws-or-aws-services-with-nlb) |
| **Box, Confluence, Dropbox, Google Drive, Jira, OneDrive, Outlook, Salesforce, SharePoint, Slack, Zendesk** | ❌ | SaaS — requires public egress | Requires [public egress](about:blank#optional-enabling-public-egress) |
| **Google Cloud Storage** | ❌ | Cross-cloud not supported | Requires public egress |
| **Snowflake (multi-cloud/SaaS)** | Varies | Native if on AWS; public egress otherwise | See Snowflake section |

---

## AWS PrivateLink Specific Information

This section outlines the information required by both parties to establish AWS PrivateLink. For connectivity into the Customer, depending on the service to be accessed there are different data points to capture. If Unstructured is accessing multiple services, we require the information for each one.

### Connections into Unstructured VPC (AWS)

This enables Customer applications to access the Unstructured Platform (UI and API).

| Order | Information Required | Description | Example | Who |
| --- | --- | --- | --- | --- |
| 1 | VPC Endpoint Service Name | Service name for Unstructured Endpoint | `com.amazonaws.vpce.us-west-2.vpce-svc-0abc123` | Unstructured |
| 1 | Service Region | Region where Unstructured’s service is hosted | `us-east-1` | Unstructured |
| 2 | AWS Account ID | 12-digit AWS Account Identifier | `123456789012` | Customer |
| 2 | AWS Region | Region where VPC Endpoint will be created | `us-east-1` | Customer |
| 2 | VPC ID | VPC where endpoint will be deployed | `vpc-0abc123def456789` | Customer |

### DNS Configuration for PrivateLink Access (AWS)

To access the Dedicated Instance over PrivateLink, DNS must be configured so the service hostname resolves to the private IPs of the VPC Endpoint. Clients must connect using the exact service hostname provided, because TLS is terminated using a provider-managed certificate.

**Option 1: Enable Private DNS on the VPC Endpoint (Recommended)**

If your VPC uses Route 53 for DNS resolution, enable Private DNS on the Interface VPC Endpoint. When Private DNS is enabled:
- Route 53 automatically creates DNS records for the service hostname.
- The hostname resolves to the private IPs of the VPC Endpoint.
- No manual hosted zone or records are required.

**Option 2: Manually Manage DNS Using a Private Hosted Zone**

If Private DNS cannot be enabled, configure DNS manually using Route 53:

1. Create a Route 53 Private Hosted Zone matching the service hostname domain (e.g., `privatelink.unstructuredapp.io`).
2. Create an A record or alias record pointing to the VPC Endpoint:
    
    ```
    example.privatelink.unstructuredapp.io → vpce-0abc123def456789.elb.us-east-1.vpce.amazonaws.com
    ```
    
3. Associate the hosted zone with the VPC(s) where clients will access the service.

---

### Connections into Customer VPC (AWS)

### AWS S3 (Gateway Endpoint)

| Order | Information Required | Description | Example | Who |
| --- | --- | --- | --- | --- |
| 1 | S3 Bucket Name | Buckets Unstructured needs to access | `my-documents` | Customer |
| 1 | S3 Bucket Region | Region where bucket is located | `us-east-1` | Customer |
| 2 | Unstructured IAM Role ARN | IAM Role ARN that will access S3 | `arn:aws:iam::987654321098:role/unstructured-s3-access` | Unstructured |

> **Note:** This section also covers **Delta Tables in Amazon S3** — the S3 Gateway Endpoint configuration is the same.
> 

**Example S3 Bucket Policy**

The customer must create a bucket policy that grants Unstructured’s IAM Role access to the required S3 buckets.

For read-only access:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowUnstructuredAccess",
      "Effect": "Allow",
      "Principal": {
        "AWS": "<UNSTRUCTURED_IAM_ROLE_ARN>"
      },
      "Action": [
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::<BUCKET_NAME>",
        "arn:aws:s3:::<BUCKET_NAME>/*"
      ]
    }
  ]
}
```

For write access (e.g., if S3 is a destination), add:

```json
{
  "Action": [
    "s3:GetObject",
    "s3:PutObject",
    "s3:DeleteObject",
    "s3:ListBucket"
  ]
}
```

Replace:
- `<UNSTRUCTURED_IAM_ROLE_ARN>` — Unstructured’s IAM Role ARN (provided during setup).
- `<BUCKET_NAME>` — Your S3 bucket name.

---

### AWS Bedrock

Amazon Bedrock is accessed via AWS-provided VPC endpoints. Unstructured configures VPC endpoints in our VPC to ensure all traffic to Bedrock stays off the public internet. Access to customer-specific Bedrock resources is controlled via IAM policies.

| Order | Information Required | Description | Example | Who |
| --- | --- | --- | --- | --- |
| 1 | Bedrock Region | AWS region where Bedrock resources are located | `us-east-1` | Customer |
| 1 | Model IDs / ARNs | Foundation models or custom models to access | `anthropic.claude-sonnet-4-5`, `arn:aws:bedrock:us-east-1:123456789012:custom-model/my-model` | Customer |
| 2 | Unstructured AWS Account ID | Account ID to allow in IAM/resource policies | `987654321098` | Unstructured |
| 2 | Unstructured IAM Role ARN | IAM Role ARN that will access Bedrock | `arn:aws:iam::987654321098:role/unstructured-bedrock` | Unstructured |

> Unstructured configures the Bedrock VPC endpoint on our side. The customer must create IAM policies that grant access to Unstructured’s IAM Role.
> 

**Example IAM Policy**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowBedrockModelInvocation",
      "Effect": "Allow",
      "Principal": {
        "AWS": "<UNSTRUCTURED_IAM_ROLE_ARN>"
      },
      "Action": [
        "bedrock:InvokeModel",
        "bedrock:InvokeModelWithResponseStream"
      ],
      "Resource": [
        "arn:aws:bedrock:<REGION>::foundation-model/anthropic.claude-sonnet-4-5-*",
        "arn:aws:bedrock:<REGION>::foundation-model/anthropic.claude-opus-4-5-*",
        "arn:aws:bedrock:<REGION>:<CUSTOMER_ACC_NO>:custom-model/*"
      ]
    }
  ]
}
```

Replace:
- `<UNSTRUCTURED_IAM_ROLE_ARN>` — Unstructured’s AWS IAM Role ARN (provided during setup).
- `<CUSTOMER_ACC_NO>` — Your AWS Account ID.
- `<REGION>` — Your Bedrock region.

---

### AWS MSK (Kafka)

Amazon MSK supports native multi-VPC private connectivity via PrivateLink. This enables Unstructured to connect to the customer’s MSK cluster (as a Kafka source) entirely within the AWS private network. The customer must have an MSK cluster with **Multi-VPC Connectivity** enabled.

> **Note:** MSK Multi-VPC Connectivity requires MSK cluster type: **provisioned** (not serverless). The cluster must use TLS or SASL/TLS authentication.
> 

| Order | Information Required | Description | Example | Who |
| --- | --- | --- | --- | --- |
| 1 | MSK Cluster ARN | ARN of the MSK cluster | `arn:aws:kafka:us-east-1:123456789012:cluster/my-cluster/abc-123` | Customer |
| 1 | MSK Cluster Region | AWS region where cluster is deployed | `us-east-1` | Customer |
| 1 | Kafka Port | Port the brokers listen on | `9094` (TLS) or `9096` (SASL/TLS) | Customer |
| 1 | Topic Name(s) | Kafka topics Unstructured needs to read | `documents-raw`, `documents-processed` | Customer |
| 2 | Unstructured AWS Account ID | Account ID to add as allowed principal | `987654321098` | Unstructured |
| 3 | VPC Endpoint Service Name | Service name created when Multi-VPC Connectivity is enabled | `com.amazonaws.vpce.us-east-1.vpce-svc-0abc123` | Customer |
| 3 | Bootstrap Broker Endpoints | Private broker DNS names for the cluster | `b-1.mycluster.abc123.kafka.us-east-1.amazonaws.com:9094` | Customer |

**Enabling MSK Multi-VPC Connectivity**

Using AWS Console:
1. Navigate to **Amazon MSK** > select your cluster.
2. Choose **Actions** > **Edit cluster connectivity**.
3. Enable **Multi-VPC connectivity**.
4. Confirm — MSK will create a VPC Endpoint Service automatically.

Using AWS CLI:

```bash
aws kafka update-connectivity \
  --cluster-arn "<MSK_CLUSTER_ARN>" \
  --connectivity-info '{
    "VpcConnectivity": {
      "ClientAuthentication": {
        "Tls": { "Enabled": true }
      }
    }
  }'
```

After enabling, retrieve the VPC Endpoint Service name:

```bash
aws kafka describe-cluster \
  --cluster-arn "<MSK_CLUSTER_ARN>" \
  --query 'ClusterInfo.BrokerNodeGroupInfo.ConnectivityInfo'
```

**Adding Unstructured as an Allowed Principal**

Once Multi-VPC Connectivity is enabled, add Unstructured’s AWS Account ID as an allowed principal on the endpoint service:

```bash
aws ec2 modify-vpc-endpoint-service-permissions \
  --service-id <MSK_ENDPOINT_SERVICE_ID> \
  --add-allowed-principals "arn:aws:iam::<UNSTRUCTURED_AWS_ACCOUNT_ID>:root"
```

Replace:
- `<MSK_ENDPOINT_SERVICE_ID>` — The endpoint service ID created by MSK Multi-VPC Connectivity.
- `<UNSTRUCTURED_AWS_ACCOUNT_ID>` — Unstructured’s AWS Account ID (provided during setup).

---

### AWS OpenSearch Service

Amazon OpenSearch Service supports native Interface VPC Endpoints. Unstructured creates a VPC endpoint in our VPC targeting the customer’s OpenSearch domain.

| Order | Information Required | Description | Example | Who |
| --- | --- | --- | --- | --- |
| 1 | OpenSearch Domain ARN | ARN of the OpenSearch domain | `arn:aws:es:us-east-1:123456789012:domain/my-domain` | Customer |
| 1 | OpenSearch Domain Region | AWS region where domain is deployed | `us-east-1` | Customer |
| 1 | Service Port | Port the service listens on | `443` | Customer |
| 2 | Unstructured AWS Account ID | Account ID to add as allowed principal | `987654321098` | Unstructured |
| 2 | Unstructured IAM Role ARN | IAM Role that will access OpenSearch | `arn:aws:iam::987654321098:role/unstructured-opensearch` | Unstructured |
| 3 | VPC Endpoint DNS | The endpoint DNS name for connection | `vpc-my-domain-xyz.us-east-1.es.amazonaws.com` | Customer |

**Example Domain Access Policy**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "<UNSTRUCTURED_IAM_ROLE_ARN>"
      },
      "Action": [
        "es:ESHttpGet",
        "es:ESHttpHead",
        "es:ESHttpPost",
        "es:ESHttpPut",
        "es:ESHttpDelete"
      ],
      "Resource": "arn:aws:es:<REGION>:<CUSTOMER_ACC_NO>:domain/<DOMAIN_NAME>/*"
    }
  ]
}
```

Replace:
- `<UNSTRUCTURED_IAM_ROLE_ARN>` — Unstructured’s AWS Role ARN (provided during setup).
- `<CUSTOMER_ACC_NO>` — Your AWS Account ID.
- `<REGION>` — Your OpenSearch region.
- `<DOMAIN_NAME>` — Your OpenSearch domain name.

---

### AWS OpenSearch Serverless

> **Important:** OpenSearch Serverless uses a fundamentally different access model compared to OpenSearch Service. It does not use resource-based access policies. Instead, access is controlled through **data access policies** and **network access policies** tied to VPC endpoints.
> 

| Order | Information Required | Description | Example | Who |
| --- | --- | --- | --- | --- |
| 1 | Collection Name | Name of the OpenSearch Serverless collection | `my-vector-store` | Customer |
| 1 | Collection ARN | Full ARN of the collection | `arn:aws:aoss:us-east-1:123456789012:collection/abc123` | Customer |
| 1 | Collection Endpoint | HTTPS endpoint of the collection | `abc123.us-east-1.aoss.amazonaws.com` | Customer |
| 1 | Collection Region | AWS region where collection is deployed | `us-east-1` | Customer |
| 2 | Unstructured AWS Account ID | Account ID to add to network access policy | `987654321098` | Unstructured |
| 2 | Unstructured IAM Role ARN | IAM Role ARN to grant data access | `arn:aws:iam::987654321098:role/unstructured-aoss` | Unstructured |
| 3 | VPC Endpoint ID | VPC endpoint ID created by Unstructured for `aoss.amazonaws.com` | `vpce-0abc123def456789` | Unstructured |

**Step 1: Create a Network Access Policy**

The network access policy must allow Unstructured’s VPC endpoint to access the collection. Create or update the network policy for your collection:

```json
[
  {
    "Rules": [
      {
        "Resource": ["collection/my-vector-store"],
        "ResourceType": "collection"
      }
    ],
    "AllowFromPublic": false,
    "SourceVPCEs": ["<UNSTRUCTURED_VPC_ENDPOINT_ID>"]
  }
]
```

Using AWS CLI:

```bash
aws opensearchserverless update-security-policy \
  --name "my-network-policy" \
  --type network \
  --policy '[{"Rules":[{"Resource":["collection/my-vector-store"],"ResourceType":"collection"}],"AllowFromPublic":false,"SourceVPCEs":["<UNSTRUCTURED_VPC_ENDPOINT_ID>"]}]'
```

**Step 2: Create a Data Access Policy**

The data access policy grants Unstructured’s IAM Role permissions to read/write the collection’s indexes.

For a vector store destination (read/write):

```json
[
  {
    "Rules": [
      {
        "Resource": ["index/my-vector-store/*"],
        "Permission": [
          "aoss:CreateIndex",
          "aoss:DeleteIndex",
          "aoss:UpdateIndex",
          "aoss:DescribeIndex",
          "aoss:ReadDocument",
          "aoss:WriteDocument"
        ],
        "ResourceType": "index"
      },
      {
        "Resource": ["collection/my-vector-store"],
        "Permission": ["aoss:DescribeCollectionItems"],
        "ResourceType": "collection"
      }
    ],
    "Principal": ["<UNSTRUCTURED_IAM_ROLE_ARN>"]
  }
]
```

Using AWS CLI:

```bash
aws opensearchserverless create-access-policy \
  --name "unstructured-access" \
  --type data \
  --policy '[{"Rules":[{"Resource":["index/my-vector-store/*"],"Permission":["aoss:CreateIndex","aoss:DeleteIndex","aoss:UpdateIndex","aoss:DescribeIndex","aoss:ReadDocument","aoss:WriteDocument"],"ResourceType":"index"},{"Resource":["collection/my-vector-store"],"Permission":["aoss:DescribeCollectionItems"],"ResourceType":"collection"}],"Principal":["<UNSTRUCTURED_IAM_ROLE_ARN>"]}]'
```

Replace:
- `<UNSTRUCTURED_VPC_ENDPOINT_ID>` — VPC Endpoint ID provided by Unstructured (from Step 2 of the information exchange).
- `<UNSTRUCTURED_IAM_ROLE_ARN>` — Unstructured’s IAM Role ARN (provided during setup).
- `my-vector-store` — Your OpenSearch Serverless collection name.

---

### AWS Databricks

Databricks on AWS supports native PrivateLink connectivity. The customer must have a Databricks Enterprise plan with a customer-managed VPC and PrivateLink enabled on their workspace.

| Order | Information Required | Description | Example | Who |
| --- | --- | --- | --- | --- |
| 1 | Databricks Workspace URL | The workspace URL | `myworkspace.cloud.databricks.com` | Customer |
| 1 | Databricks Workspace Region | AWS region where workspace is deployed | `us-east-1` | Customer |
| 1 | Private Access Level | Whether access is at ACCOUNT or ENDPOINT level | `ACCOUNT`, `ENDPOINT` | Customer |
| 2 | Unstructured VPC Endpoint ID | VPC Endpoint ID to add to allowed list (if ENDPOINT level) | `vpce-0abc123def456789` | Unstructured |
| 3 | Workspace VPC Endpoint DNS | The private endpoint DNS for the workspace | `myworkspace.privatelink.cloud.databricks.com` | Customer |

**Example: Databricks Private Access Settings (ENDPOINT level)**

If using ENDPOINT level access, add Unstructured’s VPC Endpoint ID to the allowed list via the Databricks Account Console or API:

```json
{
  "private_access_settings_name": "unstructured-access",
  "region": "<REGION>",
  "public_access_enabled": false,
  "private_access_level": "ENDPOINT",
  "allowed_vpc_endpoint_ids": [
    "<UNSTRUCTURED_VPCE_ID>"
  ]
}
```

Replace:
- `<UNSTRUCTURED_VPCE_ID>` — VPC Endpoint ID provided by Unstructured.
- `<REGION>` — Your Databricks region.

> For ACCOUNT level access, no explicit endpoint allowlisting is required — any VPC endpoint registered in the Databricks account can connect.
> 

---

### ~~Snowflake on AWS~~

~~Snowflake supports AWS PrivateLink via Snowflake’s native Private Link feature. This is available for Snowflake accounts hosted on AWS. The customer must have a **Business Critical** or higher Snowflake edition to use Private Link.~~

| Order | Information Required | Description | Example | Who |
| --- | --- | --- | --- | --- |
| 1 | Snowflake Account Identifier | The Snowflake account identifier | `myorg-myaccount` | Customer |
| 1 | Snowflake Account Region | AWS region where account is hosted | `us-east-1` | Customer |
| 2 | Unstructured AWS Account ID | AWS Account ID to authorize for Private Link | `987654321098` | Unstructured |
| 3 | Snowflake Private Link URL | Private Link hostname after enablement | `myorg-myaccount.privatelink.snowflakecomputing.com` | Customer |
| 3 | Snowflake VPC Endpoint Service Name | The service name for Snowflake’s endpoint service | `com.amazonaws.vpce.us-east-1.vpce-svc-0abc123` | Customer |

**~~Enabling Snowflake Private Link~~**

1. ~~Contact Snowflake Support or your Snowflake account representative to enable Private Link for your account and authorize Unstructured’s AWS Account ID.~~
2. ~~Once enabled, retrieve the Private Link configuration:~~

```sql
SELECT SYSTEM$GET_PRIVATELINK_CONFIG();
```

~~This returns the VPC Endpoint Service name and private hostname that Unstructured will need.~~

1. ~~Share the output with Unstructured via a support ticket. Unstructured will create a VPC endpoint and provide the VPC Endpoint ID.~~
2. ~~Authorize Unstructured’s VPC Endpoint in Snowflake:~~

```sql
SELECT SYSTEM$AUTHORIZE_PRIVATELINK('<UNSTRUCTURED_AWS_ACCOUNT_ID>', '<UNSTRUCTURED_VPC_ENDPOINT_ID>');
```

~~Replace:
- `<UNSTRUCTURED_AWS_ACCOUNT_ID>` — Unstructured’s AWS Account ID (provided during setup).
- `<UNSTRUCTURED_VPC_ENDPOINT_ID>` — VPC Endpoint ID provided by Unstructured.~~

---

### AWS Managed Services with Native PrivateLink

Some AWS managed services support native PrivateLink endpoints. The customer creates a VPC endpoint for their service, and Unstructured connects to it. This pattern applies to services like **Amazon ElastiCache (Redis)** and **AWS Elasticsearch Service (legacy)**.

| Order | Information Required | Description | Example | Who |
| --- | --- | --- | --- | --- |
| 1 | Service Type | The AWS Service being accessed | `ElastiCache`, `Elasticsearch` | Customer |
| 1 | Service Region | Region where the service is hosted | `us-east-1` | Customer |
| 1 | Service Port | Port the service listens on | `6379` (Redis), `443` (Elasticsearch) | Customer |
| 1 | Resource ARN | ARN of the resource | `arn:aws:elasticache:us-east-1:123456789012:cluster/my-cache` | Customer |
| 2 | Unstructured AWS Account ID | Account ID to add as allowed principal | `987654321098` | Unstructured |
| 2 | Unstructured IAM Role ARN | IAM Role that will access the service | `arn:aws:iam::987654321098:role/unstructured-access` | Unstructured |
| 3 | VPC Endpoint ID | The service-managed VPC endpoint ID | `vpce-0abc123def456789` | Customer |
| 3 | VPC Endpoint DNS | The endpoint DNS name for connection | `vpce-0abc123.us-east-1.es.amazonaws.com` | Customer |

---

### Customer Managed Services (AWS) or AWS Services with NLB

This applies to:
- Applications the customer is **self-hosting** in their AWS VPC (e.g., Elasticsearch, MongoDB, Couchbase).
- AWS services that do **not** have native PrivateLink support and require an NLB front-end, such as **Amazon RDS, Aurora, Redshift, DocumentDB**.

| Order | Information Required | Description | Example | Who |
| --- | --- | --- | --- | --- |
| 1 | Service Type | The service being accessed | `PostgreSQL (RDS)`, `MongoDB`, `Elasticsearch` | Customer |
| 1 | Service Region | Region where the service is hosted | `us-east-1` | Customer |
| 1 | Service Port | Port the service listens on | `5432` (PostgreSQL), `27017` (MongoDB), `9200` (Elasticsearch) | Customer |
| 2 | Unstructured AWS Account ID | Account ID to add as allowed principal | `987654321098` | Unstructured |
| 2 | Unstructured IAM Role ARN | IAM Role that will access the service | `arn:aws:iam::987654321098:role/unstructured-access` | Unstructured |
| 3 | VPC Endpoint Service Name | Service name for the endpoint service fronting the NLB | `com.amazonaws.vpce.us-east-1.vpce-svc-0abc123` | Customer |
| 3 | Service Endpoint | The endpoint URL for connection | Custom DNS or endpoint service DNS | Customer |

> The customer must create: (1) a Network Load Balancer targeting their managed service, and (2) a VPC Endpoint Service pointing to the NLB.
> 

**Example: Allow Unstructured as a Principal on the Endpoint Service**

Using AWS Console:
1. Navigate to **VPC > Endpoint Services**.
2. Select your endpoint service.
3. Go to the **“Allow principals”** tab and click **“Allow principals”**.
4. Add the Unstructured ARN captured during the setup process.

Using AWS CLI:

```bash
aws ec2 modify-vpc-endpoint-service-permissions \
  --service-id vpce-svc-0abc123def456789 \
  --add-allowed-principals "<UNSTRUCTURED_IAM_ROLE_ARN>"
```

Replace:
- `<UNSTRUCTURED_IAM_ROLE_ARN>` — Unstructured’s AWS Role ARN (provided during setup).

---

## Azure Private Link Specific Information

This section outlines the information required by both parties to establish Azure Private Link. For connectivity into the Customer, depending on the service to be accessed there are different data points to capture. If Unstructured is accessing multiple services, we require the information for each one.

### Azure Connector Coverage

| Connector | PrivateLink Supported | Approach | Configuration Section |
| --- | --- | --- | --- |
| **Customer → Unstructured (UI/API)** | ✅ | Private Endpoint | [Link](about:blank#connections-into-unstructured-vpc-azure) |
| **Azure Blob Storage / ADLS Gen2** | ✅ | Private Endpoint | [Link](about:blank#azure-blob-storage) |
| **Azure OpenAI** | ✅ | Private Endpoint | [Link](about:blank#azure-openai) |
| **Azure OpenAI via API Management** | ✅ | Private Endpoint + APIM Private mode | Contact Unstructured |
| **Azure AI Search** | ✅ | Private Endpoint | [Link](about:blank#azure-managed-services) |
| **Databricks (Azure)** | ✅ | Private Link | [Link](about:blank#azure-databricks) |
| **Azure SQL / Cosmos DB / PostgreSQL / MySQL / Synapse** | ✅ | Private Endpoint | [Link](about:blank#azure-managed-services) |
| **Customer Managed Services (Azure)** | ✅ | Private Link Service + Standard Load Balancer | [Link](about:blank#customer-managed-services-azure) |
| **OneDrive / SharePoint / Outlook** | ❌ | Microsoft SaaS — requires public egress | Requires public egress |
| **Google Cloud Storage** | ❌ | Cross-cloud not supported | Requires public egress |

### Connections into Unstructured VPC (Azure)

This enables Customer applications to access the Unstructured Platform (UI and API).

| Order | Information Required | Description | Example | Who |
| --- | --- | --- | --- | --- |
| 1 | Private Link Service Resource ID | Resource ID of Unstructured’s Private Link Service | `/subscriptions/…/providers/Microsoft.Network/privateLinkServices/uio-pls` | Unstructured |
| 1 | Private Link Service Alias | Alias for Unstructured’s Private Link Service | `uio-pls.abc123.eastus.azure.privatelinkservice` | Unstructured |
| 1 | Service Region | Region where Unstructured’s service is hosted | `eastus` | Unstructured |
| 2 | Azure Subscription ID | Customer’s Azure Subscription ID (to approve connection) | `a1b2c3d4-e5f6-7890-abcd-ef1234567890` | Customer |
| 2 | Azure Region | Region where Private Endpoint will be created | `eastus` | Customer |
| 2 | Virtual Network Name | VNet where endpoint will be deployed | `customer-vnet` | Customer |
| 2 | Subnet Name | Subnet for the private endpoint | `private-endpoints-subnet` | Customer |
| 2 | Resource Group | Resource group containing the VNet | `customer-network-rg` | Customer |

### DNS Configuration for PrivateLink Access (Azure)

1. Create a Private DNS Zone matching the service hostname domain (e.g., `privatelink.unstructuredapp.io`).
2. Create an A record for the full service hostname pointing to the private IP of your Private Endpoint:
    
    ```
    example.privatelink.unstructuredapp.io → 10.12.34.56
    ```
    
3. Link the Private DNS Zone to the VNet(s) where clients will access the service.

---

### Connections into Customer VNet (Azure)

### Azure Blob Storage

This applies to Azure Blob Storage and Azure Data Lake Storage Gen2 (ADLS Gen2).

| Order | Information Required | Description | Example | Who |
| --- | --- | --- | --- | --- |
| 1 | Storage Account Name | Name of the Azure Storage Account | `customerstorageacct` | Customer |
| 1 | Storage Account Resource ID | Full Azure Resource ID of the storage account | `/subscriptions/…/providers/Microsoft.Storage/storageAccounts/customerstorageacct` | Customer |
| 1 | Container Name(s) | Containers Unstructured needs to access | `documents, processed-data` | Customer |
| 1 | Storage Account Region | Region where storage account is located | `eastus` | Customer |
| 1 | Sub-resource Type | `blob`, `dfs` (for ADLS Gen2), `file`, `table`, `queue` | `blob`, `dfs` | Customer |
| 2 | Unstructured Service Principal ID | Service Principal ID for RBAC role assignment | `b2c3d4e5-f6a7-8901-bcde-f23456789012` | Unstructured |
| 2 | Unstructured Subscription ID | Subscription ID for Private Endpoint approval | `a1b2c3d4-e5f6-7890-abcd-ef1234567890` | Unstructured |

> For ADLS Gen2, use sub-resource type `dfs` for hierarchical namespace operations. The customer must approve the Private Endpoint connection request in the Storage Account > Networking > Private endpoint connections.
> 

**Example: Azure Role Assignment**

Using Azure CLI for read-only access:

```bash
az role assignment create \
  --assignee "<UNSTRUCTURED_SP_ID>" \
  --role "Storage Blob Data Reader" \
  --scope "/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/<RESOURCE_GROUP>/providers/Microsoft.Storage/storageAccounts/<STORAGE_ACCOUNT>"
```

For read/write access, replace `"Storage Blob Data Reader"` with `"Storage Blob Data Contributor"`.

Replace:
- `<UNSTRUCTURED_SP_ID>` — Unstructured’s Service Principal ID (provided during setup).
- `<SUBSCRIPTION_ID>` — Your Azure Subscription ID.
- `<RESOURCE_GROUP>` — Your Resource Group name.
- `<STORAGE_ACCOUNT>` — Your Storage Account name.

---

### Azure OpenAI

Azure OpenAI supports Private Endpoint access. Unstructured creates a Private Endpoint in our VNet to access the customer’s Azure OpenAI resource privately.

| Order | Information Required | Description | Example | Who |
| --- | --- | --- | --- | --- |
| 1 | Azure OpenAI Resource Name | Name of the Azure OpenAI resource | `customer-openai` | Customer |
| 1 | Azure OpenAI Resource ID | Full Azure Resource ID | `/subscriptions/…/providers/Microsoft.CognitiveServices/accounts/customer-openai` | Customer |
| 1 | Azure OpenAI Region | Region where the resource is deployed | `eastus` | Customer |
| 1 | Deployment Name(s) | Model deployment names to access | `gpt-4-deployment, embedding-deployment` | Customer |
| 1 | Sub-resource Type | Always `account` for Azure OpenAI | `account` | Customer |
| 2 | Unstructured Service Principal ID | Service Principal ID for RBAC role assignment | `b2c3d4e5-f6a7-8901-bcde-f23456789012` | Unstructured |
| 2 | Unstructured Subscription ID | Subscription ID for Private Endpoint approval | `a1b2c3d4-e5f6-7890-abcd-ef1234567890` | Unstructured |

**Example: Azure Role Assignment for OpenAI**

```bash
az role assignment create \
  --assignee "<UNSTRUCTURED_SP_ID>" \
  --role "Cognitive Services OpenAI User" \
  --scope "/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/<RESOURCE_GROUP>/providers/Microsoft.CognitiveServices/accounts/<OPENAI_RESOURCE>"
```

After role assignment, configure the firewall to deny public access and approve the pending Private Endpoint connection request in the Azure Portal under the OpenAI resource > Networking > Private endpoint connections.

---

### Azure Databricks

Azure Databricks supports Private Link for both front-end (user-to-workspace) and back-end (compute-to-control plane) connectivity. The customer must have Private Link enabled on their workspace.

| Order | Information Required | Description | Example | Who |
| --- | --- | --- | --- | --- |
| 1 | Databricks Workspace URL | The workspace URL | `adb-1234567890123456.12.azuredatabricks.net` | Customer |
| 1 | Databricks Workspace Resource ID | Full Azure Resource ID of the workspace | `/subscriptions/…/providers/Microsoft.Databricks/workspaces/customer-workspace` | Customer |
| 1 | Databricks Workspace Region | Azure region where workspace is deployed | `eastus` | Customer |
| 1 | Sub-resource Type | `databricks_ui_api` for workspace access | `databricks_ui_api` | Customer |
| 2 | Unstructured Subscription ID | Subscription ID for Private Endpoint approval | `a1b2c3d4-e5f6-7890-abcd-ef1234567890` | Unstructured |
| 3 | Private Endpoint DNS | The private endpoint DNS for the workspace | `adb-1234567890123456.12.privatelink.azuredatabricks.net` | Customer |

After Unstructured creates the Private Endpoint, approve the connection:

```bash
az network private-endpoint-connection approve \
  --resource-group "<RESOURCE_GROUP>" \
  --resource-name "<WORKSPACE_NAME>" \
  --name "<PRIVATE_ENDPOINT_NAME>" \
  --type Microsoft.Databricks/workspaces
```

---

### Azure Managed Services

This applies to Azure-managed services that support Private Endpoint access, including: **Azure AI Search, Azure SQL Database, Azure SQL Managed Instance, Azure Cosmos DB, Azure Database for PostgreSQL, Azure Database for MySQL,** and **Azure Synapse Analytics**.

| Order | Information Required | Description | Example | Who |
| --- | --- | --- | --- | --- |
| 1 | Service Type | The Azure managed service being accessed | `Azure AI Search`, `Azure SQL` | Customer |
| 1 | Resource Name | Name of the Azure resource | `my-search-service` | Customer |
| 1 | Resource ID | Full Azure Resource ID | `/subscriptions/…/providers/Microsoft.Search/searchServices/my-search` | Customer |
| 1 | Service Region | Region where the service is hosted | `eastus` | Customer |
| 1 | Sub-Resource Type | The sub-resource type for Private Link (see table below) | `searchService`, `sqlServer` | Customer |
| 1 | Service Port | Port the service listens on | `443` (AI Search), `1433` (SQL) | Customer |
| 2 | Unstructured Service Principal ID | Service Principal ID for RBAC role assignment | `b2c3d4e5-f6a7-8901-bcde-f23456789012` | Unstructured |
| 2 | Unstructured Subscription ID | Subscription ID to approve for Private Endpoint | `a1b2c3d4-e5f6-7890-abcd-ef1234567890` | Unstructured |

**Sub-resource types by service:**

| Service | Sub-Resource Type |
| --- | --- |
| AI Search | `searchService` |
| Azure SQL Database | `sqlServer` |
| Azure SQL Managed Instance | `managedInstance` |
| Azure Cosmos DB (SQL API) | `Sql` |
| Azure Cosmos DB (MongoDB API) | `MongoDB` |
| Azure Database for PostgreSQL | `postgresqlServer` |
| Azure Database for MySQL | `mysqlServer` |
| Azure Synapse Analytics | `Sql`, `SqlOnDemand`, `Dev` |

---

### Customer Managed Services (Azure)

This applies to applications the customer is self-hosting in their Azure VNet. The customer must create a Private Link Service in front of their application, backed by an Azure Standard Load Balancer.

| Order | Information Required | Description | Example | Who |
| --- | --- | --- | --- | --- |
| 1 | Private Link Service Name | Name of the customer’s Private Link Service | `customer-app-pls` | Customer |
| 1 | Private Link Service Resource ID | Full Resource ID of the Private Link Service | `/subscriptions/…/providers/Microsoft.Network/privateLinkServices/customer-app-pls` | Customer |
| 1 | Service Region | Region where the service is hosted | `eastus` | Customer |
| 1 | Service Port | Port(s) the service listens on | `443`, `8080` | Customer |
| 2 | Unstructured Subscription ID | Subscription ID to approve for connection | `a1b2c3d4-e5f6-7890-abcd-ef1234567890` | Unstructured |

> The customer must create: (1) an Azure Standard Load Balancer fronting their application, and (2) a Private Link Service attached to the Load Balancer’s frontend IP. Unstructured then creates a Private Endpoint targeting the customer’s Private Link Service.
> 

**Example: Creating Private Link Service using Azure CLI**

```bash
# Create Private Link Service
az network private-link-service create \
  --name "customer-app-pls" \
  --resource-group "<RESOURCE_GROUP>" \
  --vnet-name "<VNET_NAME>" \
  --subnet "<SUBNET_NAME>" \
  --lb-name "<LOAD_BALANCER_NAME>" \
  --lb-frontend-ip-configs "<FRONTEND_IP_CONFIG_NAME>" \
  --location "<REGION>"

# Approve connection after Unstructured creates Private Endpoint
az network private-link-service connection approve \
  --resource-group "<RESOURCE_GROUP>" \
  --service-name "customer-app-pls" \
  --name "<CONNECTION_NAME>"
```

> **Private API Gateway Scenario:** If the customer’s application uses Azure API Management in private-only (internal VNet) mode, the API Management service cannot be directly exposed via Private Link Service. In this case, deploy an Azure Standard Load Balancer in front of API Management and create a Private Link Service pointing to the Load Balancer.
>