import Cake.LevelSpecific.Tree.Wasps.Behaviours.WaspBehaviourCapability;
import Cake.LevelSpecific.Tree.Wasps.Weapons.HomingProjectile.WaspHomingProjectile;
import Cake.LevelSpecific.Tree.Wasps.Weapons.WaspSpinningWeaponComponent;

// Stay in this state until we have a target (wielder will give us one)
class UWaspHomingProjectileIdleCapability : UWaspBehaviourCapability
{
    default State = EWaspState::Idle;

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Super::OnActivated(ActivationParams);
		UWaspHomingProjectileComponent HomingComp = UWaspHomingProjectileComponent::Get(Owner);
		Owner.AttachToComponent(HomingComp.Launcher);
		Owner.SetActorHiddenInGame(true);	
		Owner.SetActorEnableCollision(false);

		// Show wielder weapon (for now)
		UWaspWeaponSpinningComponent LaunchedWeapon = UWaspWeaponSpinningComponent::Get(UWaspHomingProjectileComponent::Get(Owner).Wielder);
		LaunchedWeapon.SetHiddenInGame(false);	
		HomingComp.Returned();
    }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (BehaviourComponent.HasValidTarget())
			BehaviourComponent.State = EWaspState::Telegraphing;
	}
}

