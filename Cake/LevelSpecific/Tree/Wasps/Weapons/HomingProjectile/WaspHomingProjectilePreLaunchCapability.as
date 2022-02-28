import Cake.LevelSpecific.Tree.Wasps.Behaviours.WaspBehaviourCapability;
import Cake.LevelSpecific.Tree.Wasps.Weapons.WaspSpinningWeaponComponent;
import Cake.LevelSpecific.Tree.Wasps.Weapons.HomingProjectile.WaspHomingProjectile;

class UWaspHomingProjectilePreLaunchCapability : UWaspBehaviourCapability
{
    default State = EWaspState::Telegraphing;

    float AttackTime;

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Super::OnActivated(ActivationParams);

		// Trigger pre-launch effects and audio
		// TODO

        // Set time for attack
        AttackTime = Time::GetGameTimeSeconds() + Settings.PrepareAttackDuration;
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
        if (!BehaviourComponent.HasValidTarget())
        {
            BehaviourComponent.State = EWaspState::Idle; // Lost target
            return;
        }

        if (Time::GetGameTimeSeconds() > AttackTime)
        {
            BehaviourComponent.State = EWaspState::Attack;

			// Show yourself! Weapon should really always be shown, but for now we hax it like this since we're testing.
			Owner.SetActorHiddenInGame(false);	
			UWaspHomingProjectileComponent HomingComp = UWaspHomingProjectileComponent::Get(Owner);
			Owner.SetActorLocationAndRotation(HomingComp.Launcher.WorldLocation, (BehaviourComponent.Target.ActorLocation - Owner.ActorLocation).Rotation());
			UWaspWeaponSpinningComponent LaunchedWeapon = UWaspWeaponSpinningComponent::Get(HomingComp.Wielder);
			LaunchedWeapon.SetHiddenInGame(true);	
            return;
        }
    }
}

