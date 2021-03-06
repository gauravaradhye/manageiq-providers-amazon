class ManageIQ::Providers::Amazon::Inventory::Target::TargetCollection < ManageIQ::Providers::Amazon::Inventory::Target
  def initialize_inventory_collections
    add_targeted_inventory_collections
    add_remaining_inventory_collections([cloud, network, storage], :strategy => :local_db_find_one)

    add_inventory_collection(
      cloud.vm_and_miq_template_ancestry(
        :dependency_attributes => {
          :vms           => [inventory_collections[:vms]],
          :miq_templates => [inventory_collections[:miq_templates]]
        }
      )
    )

    add_inventory_collection(
      cloud.orchestration_stack_ancestry(
        :dependency_attributes => {
          :orchestration_stacks           => [inventory_collections[:orchestration_stacks]],
          :orchestration_stacks_resources => [inventory_collections[:orchestration_stacks_resources]]
        }
      )
    )
  end

  private

  def cloud
    ManageIQ::Providers::Amazon::InventoryCollectionDefault::CloudManager
  end

  def network
    ManageIQ::Providers::Amazon::InventoryCollectionDefault::NetworkManager
  end

  def storage
    ManageIQ::Providers::Amazon::InventoryCollectionDefault::StorageManager
  end

  def add_targeted_inventory_collections
    images_refs = collector.private_images_refs.to_a + collector.shared_images_refs.to_a + collector.public_images_refs.to_a

    # Cloud
    add_vms_inventory_collections(collector.instances_refs.to_a)
    add_miq_templates_inventory_collections(images_refs)
    add_hardwares_inventory_collections(collector.instances_refs.to_a + images_refs)
    add_stacks_inventory_collections(collector.stacks_refs.to_a)

    # Network
    add_cloud_networks_inventory_collections(collector.cloud_networks_refs.to_a)
    add_cloud_subnets_inventory_collections(collector.cloud_subnets_refs.to_a)
    add_network_ports_inventory_collections(collector.instances_refs.to_a + collector.network_ports_refs.to_a)
    add_security_groups_inventory_collections(collector.security_groups_refs.to_a)
    add_floating_ips_inventory_collections(collector.floating_ips_refs.to_a)
    add_load_balancers_collections(collector.load_balancers_refs.to_a)

    # Storage
    add_cloud_volumes_collections(collector.cloud_volumes_refs.to_a)
    add_cloud_volume_snapshots_collections(collector.cloud_volume_snapshots_refs.to_a)
  end

  def add_vms_inventory_collections(manager_refs)
    return if manager_refs.blank?

    add_inventory_collection(
      cloud.vms(
        :arel     => ems.vms.where(:ems_ref => manager_refs),
        :strategy => :find_missing_in_local_db
      )
    )
    add_inventory_collection(
      cloud.disks(
        :arel     => ems.disks.joins(:hardware => :vm_or_template).where(
          :hardware => {'vms' => {:ems_ref => manager_refs}}
        ),
        :strategy => :find_missing_in_local_db
      )
    )
    add_inventory_collection(
      cloud.networks(
        :arel     => ems.networks.joins(:hardware => :vm_or_template).where(
          :hardware => {'vms' => {:ems_ref => manager_refs}}
        ),
        :strategy => :find_missing_in_local_db
      )
    )
  end

  def add_miq_templates_inventory_collections(manager_refs)
    return if manager_refs.blank?

    add_inventory_collection(
      cloud.miq_templates(
        :arel     => ems.miq_templates.where(:ems_ref => manager_refs),
        :strategy => :find_missing_in_local_db
      )
    )
  end

  def add_hardwares_inventory_collections(manager_refs)
    return if manager_refs.blank?

    add_inventory_collection(
      cloud.hardwares(
        :arel     => ems.hardwares.joins(:vm_or_template).where(
          'vms' => {:ems_ref => manager_refs}
        ),
        :strategy => :find_missing_in_local_db
      )
    )
  end

  def add_stacks_inventory_collections(manager_refs)
    return if manager_refs.blank?

    add_inventory_collection(
      cloud.orchestration_stacks(
        :arel     => ems.orchestration_stacks.where(:ems_ref => manager_refs),
        :strategy => :find_missing_in_local_db
      )
    )

    add_inventory_collection(
      cloud.orchestration_stacks(
        :arel     => ems.orchestration_stacks_resources.references(:orchestration_stacks).where(
          :orchestration_stacks => {:ems_ref => manager_refs}
        ),
        :strategy => :find_missing_in_local_db
      )
    )

    add_inventory_collection(
      cloud.orchestration_stacks_outputs(
        :arel     => ems.orchestration_stacks_outputs.references(:orchestration_stacks).where(
          :orchestration_stacks => {:ems_ref => manager_refs}
        ),
        :strategy => :find_missing_in_local_db
      )
    )

    add_inventory_collection(
      cloud.orchestration_stacks_parameters(
        :arel     => ems.orchestration_stacks_parameters.references(:orchestration_stacks).where(
          :orchestration_stacks => {:ems_ref => manager_refs}
        ),
        :strategy => :find_missing_in_local_db
      )
    )

    add_inventory_collection(cloud.orchestration_templates)
  end

  def add_cloud_networks_inventory_collections(manager_refs)
    return if manager_refs.blank?

    add_inventory_collection(
      network.cloud_networks(
        :arel     => ems.network_manager.cloud_networks.where(:ems_ref => manager_refs),
        :strategy => :find_missing_in_local_db
      )
    )
  end

  def add_cloud_subnets_inventory_collections(manager_refs)
    return if manager_refs.blank?

    add_inventory_collection(
      network.cloud_subnets(
        :arel     => ems.network_manager.cloud_subnets.where(:ems_ref => manager_refs),
        :strategy => :find_missing_in_local_db
      )
    )
  end

  def add_security_groups_inventory_collections(manager_refs)
    return if manager_refs.blank?

    add_inventory_collection(
      network.security_groups(
        :arel     => ems.network_manager.security_groups.where(:ems_ref => manager_refs),
        :strategy => :find_missing_in_local_db
      )
    )
    add_inventory_collection(
      network.firewall_rules(
        :arel     => ems.network_manager.firewall_rules.references(:security_groups).where(
          :security_groups => {:ems_ref => manager_refs}
        ),
        :strategy => :find_missing_in_local_db
      )
    )
  end

  def add_network_ports_inventory_collections(manager_refs)
    return if manager_refs.blank?

    add_inventory_collection(
      network.network_ports(
        :arel     => ems.network_manager.network_ports.where(:ems_ref => manager_refs),
        :strategy => :find_missing_in_local_db
      )
    )
    add_inventory_collection(
      network.cloud_subnet_network_ports(
        :arel     => ems.network_manager.cloud_subnet_network_ports.references(:network_ports).where(
          :network_ports => {:ems_ref => manager_refs}
        ),
        :strategy => :find_missing_in_local_db
      )
    )
  end

  def add_floating_ips_inventory_collections(manager_refs)
    return if manager_refs.blank?

    add_inventory_collection(
      network.floating_ips(
        :arel     => ems.network_manager.floating_ips.where(:ems_ref => manager_refs),
        :strategy => :find_missing_in_local_db
      )
    )
  end

  def add_load_balancers_collections(manager_refs)
    return if manager_refs.blank?

    add_inventory_collection(
      network.load_balancers(
        :arel     => ems.network_manager.load_balancers.where(:ems_ref => manager_refs),
        :strategy => :find_missing_in_local_db
      )
    )

    add_inventory_collection(
      network.load_balancer_health_checks(
        :arel     => ems.network_manager.load_balancer_health_checks.where(:ems_ref => manager_refs),
        :strategy => :find_missing_in_local_db
      )
    )

    add_inventory_collection(
      network.load_balancer_health_check_members(
        :arel     => ems.network_manager.load_balancer_health_check_members.references(:load_balancer_health_checks).where(
          :load_balancer_health_checks => {:ems_ref => manager_refs}
        ),
        :strategy => :find_missing_in_local_db
      )
    )

    add_inventory_collection(
      network.load_balancer_listeners(
        :arel     => ems.network_manager.load_balancer_listeners.joins(:load_balancer).where(
          :load_balancers => {:ems_ref => manager_refs}
        ),
        :strategy => :find_missing_in_local_db
      )
    )

    add_inventory_collection(
      network.load_balancer_listener_pools(
        :arel     => ems.network_manager.load_balancer_listener_pools.joins(:load_balancer_pool).where(
          :load_balancer_pools => {:ems_ref => manager_refs}
        ),
        :strategy => :find_missing_in_local_db
      )
    )

    add_inventory_collection(
      network.load_balancer_pools(
        :arel     => ems.network_manager.load_balancer_pools.where(:ems_ref => manager_refs),
        :strategy => :find_missing_in_local_db
      )
    )

    add_inventory_collection(
      network.load_balancer_pool_member_pools(
        :arel     => ems.network_manager.load_balancer_pool_member_pools.references(:load_balancer_pools).where(:load_balancer_pools => {:ems_ref => manager_refs}),
        :strategy => :find_missing_in_local_db
      )
    )

    add_inventory_collection(
      network.load_balancer_pool_members(
        :arel     => ems.network_manager.load_balancer_pool_members.joins(:load_balancer_pool_member_pools => :load_balancer_pool).where(:load_balancer_pool_member_pools => {'load_balancer_pools' => {:ems_ref => manager_refs}}),
        :strategy => :find_missing_in_local_db
      )
    )
  end

  def add_cloud_volumes_collections(manager_refs)
    return if manager_refs.blank?

    add_inventory_collection(
      storage.cloud_volumes(
        :arel     => ems.ebs_storage_manager.cloud_volumes.where(:ems_ref => manager_refs),
        :strategy => :find_missing_in_local_db
      )
    )
  end

  def add_cloud_volume_snapshots_collections(manager_refs)
    return if manager_refs.blank?

    add_inventory_collection(
      storage.cloud_volume_snapshots(
        :arel     => ems.ebs_storage_manager.cloud_volume_snapshots.where(:ems_ref => manager_refs),
        :strategy => :find_missing_in_local_db
      )
    )
  end
end
