import Cake.LevelSpecific.Music.LevelMechanics.Classic.FollowCloud.FollowCloud;
import Cake.LevelSpecific.Music.LevelMechanics.Classic.FollowCloud.FollowCloudBoundsComponent;

class UFollowCloudBumpCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	
	default TickGroup = ECapabilityTickGroups::GamePlay;

	AFollowCloud FollowCloud;
	UFollowCloudBoundsComponent Bounds = nullptr;

    UPROPERTY(NotEditable)
	UHazeMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		FollowCloud = Cast<AFollowCloud>(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		Bounds = UFollowCloudBoundsComponent::Get(FollowCloud);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (FollowCloud.BumpDirection.IsZero())
			return EHazeNetworkActivation::DontActivate;
		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Niagara::SpawnSystemAtLocation(FollowCloud.CymbalImpactEffect, FollowCloud.BumpLocation, Owner.GetActorRotation());
		FVector HitDirection = FollowCloud.BumpDirection.GetSafeNormal();
		float Force = FollowCloud.Settings.ImpulseValue;
		if (!Bounds.IsWithinBounds(FollowCloud.ActorLocation))
			Force *= 0.2f;
		Owner.AddImpulse(HitDirection * Force);
		FollowCloud.BumpDirection = FVector::ZeroVector;
	}
}
