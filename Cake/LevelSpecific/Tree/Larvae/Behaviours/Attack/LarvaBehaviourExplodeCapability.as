import Cake.LevelSpecific.Tree.Larvae.Behaviours.LarvaBehaviourCapability;
import Cake.LevelSpecific.Tree.Wasps.Attacks.PlayerResponses.WaspExplosionHitResponseCapability;

class ULarvaBehaviourExplodeCapability : ULarvaBehaviourCapability
{
    default State = ELarvaState::Attack;

    float ExplodeTime = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
        Super::Setup(SetupParams);

		// Add response capability for all players when there are members of the team
		BehaviourComponent.Team.AddPlayersCapability(UWaspExplosionHitResponseCapability::StaticClass());
    }    

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate() != EHazeNetworkDeactivation::DontDeactivate)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		if (Time::GetGameTimeSeconds() > ExplodeTime) 
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
       	return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Super::OnActivated(ActivationParams);

        ExplodeTime = Time::GetGameTimeSeconds() + 0.3f;
        Niagara::SpawnSystemAttached(BehaviourComponent.FuseEffect, Owner.GetRootComponent(), NAME_None, FVector::ZeroVector, FRotator::ZeroRotator, EAttachLocation::SnapToTarget, true);
        BehaviourMoveComp.LeapTowards(Owner.GetActorLocation() + FVector(0.f, 0.f, 700.f));

		Owner.PlaySlotAnimation(Animation = BehaviourComponent.AnimFeature.Explode);
    }

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Super::OnDeactivated(DeactivationParams);
		if (!BehaviourComponent.bIsDead)
			BehaviourComponent.Explode();
    }
}
