# Generated by Django 5.1.4 on 2025-01-27 20:33

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('attendance', '0003_issue'),
    ]

    operations = [
        migrations.AddField(
            model_name='userprofile',
            name='blocked',
            field=models.BooleanField(default=False),
        ),
    ]
