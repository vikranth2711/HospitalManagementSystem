from diagrams import Cluster, Diagram, Edge
from diagrams.aws.compute import EC2
from diagrams.aws.database import RDS
from diagrams.aws.storage import S3
from diagrams.aws.network import CloudFront
from diagrams.custom import Custom
from diagrams.programming.language import Python
from diagrams.onprem.network import Nginx
from diagrams.onprem.client import Client

with Diagram("Hospital Management System Architecture", show=True, direction="LR"):

    mobile = Client("SwiftUI\nMobile App")

    with Cluster("AWS Cloud"):
        cloudfront = CloudFront("CloudFront CDN")

        with Cluster("Web Tier"):
            nginx = Nginx("Nginx")
            gunicorn = Custom("Gunicorn", "/Users/admin23/Python-Programs/HospitalManagementSystem/POC/backend/gunicorn-icon-2048x1245-14wjcllu.png")  # custom icon path
            django = Python("Django + DRF")

            mobile >> cloudfront >> nginx >> gunicorn >> django

        with Cluster("Data & Storage Tier"):
            db = RDS("PostgreSQL\nAWS RDS")
            media = S3("Media Files\nS3 Bucket")

            django >> Edge(label="ORM") >> db
            django >> Edge(label="Media Access") >> media

    cloudfront >> Edge(style="dotted", label="Static/Media CDN") >> media
