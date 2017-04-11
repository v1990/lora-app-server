-- +migrate Up
create table organization (
	id bigserial primary key,
	created_at timestamp with time zone not null,
	updated_at timestamp with time zone not null,
	name character varying (100) not null,
	display_name character varying (100) not null,
	can_have_gateways boolean not null
);

insert into organization (
	created_at,
	updated_at,
	name,
	display_name,
	can_have_gateways
) values(
	now(),
	now(),
	'loraserver',
	'LoRa Server',
	true
);

create unique index idx_organization_name on organization(name);

create table organization_user (
	id bigserial primary key,
	created_at timestamp with time zone not null,
	updated_at timestamp with time zone not null,
	user_id bigint not null references "user" on delete cascade,
	organization_id bigint not null references organization on delete cascade,
	is_admin boolean not null,

	unique(user_id, organization_id)
);

create index idx_organization_user_user_id on organization_user(user_id);
create index idx_organization_user_organization_id on organization_user(organization_id);

-- assign admin user to LoRa Server organization
insert into organization_user (
	created_at,
	updated_at,
	user_id,
	organization_id,
	is_admin
) (
	select
		now(),
		now(),
		u.id,
		1,
		true
	from "user" u
	where u.username = 'admin'
);

create table gateway (
	mac bytea primary key,
	name varchar(100) not null,
	description text not null,
	organization_id bigint not null references organization on delete cascade
);

create unique index idx_gateway_name on gateway(name);
create index idx_gateway_organization_id on gateway(organization_id);

alter table application
	add column organization_id bigint not null references organization on delete cascade default 1;

alter table application
	alter column organization_id drop default;

create index idx_application_organization_id on application(organization_id);

-- +migrate Down
drop index idx_application_organization_id;
alter table application
	drop column organization_id;

drop index idx_gateway_organization_id;
drop index idx_gateway_name;
drop table gateway;

drop index idx_organization_user_organization_id;
drop index idx_organization_user_user_id;
drop table organization_user;

drop index idx_organization_name;
drop table organization;