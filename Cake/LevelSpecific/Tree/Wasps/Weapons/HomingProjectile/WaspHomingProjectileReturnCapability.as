import Cake.LevelSpecific.Tree.Wasps.Behaviours.WaspBehaviourCapability;
import Cake.LevelSpecific.Tree.Wasps.Weapons.HomingProjectile.WaspHomingProjectile;

class WaspHomingProjectileReturnCapability : UWaspBehaviourCapability
{
    default State = EWaspState::Recover;

	FHazeAcceleratedFloat ToTargetAlpha;
	FHazeAcceleratedRotator ReturnRot;
	UWaspHomingProjectileComponent HomingComp;

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Super::OnActivated(ActivationParams);
		HomingComp = UWaspHomingProjectileComponent::Get(Owner);
		ReturnRot.SnapTo(Owner.ActorRotation);
		ToTargetAlpha.SnapTo(0.f);
		BehaviourComponent.SetTarget(nullptr);
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
		// Continue doing damage while returning
		BehaviourComponent.PerformSustainedAttack(0.1f);

		FVector TargetLoc = GetTargetLocation();
		FVector ToTarget = TargetLoc - Owner.ActorLocation;
		ReturnRot.AccelerateTo(ToTarget.Rotation(), FMath::Max(0.5f, Settings.RecoverDuration - BehaviourComponent.StateDuration), DeltaTime);
		if (Owner.ActorForwardVector.DotProduct(ToTarget) > 0.f)
			ToTargetAlpha.AccelerateTo(1.f, Settings.RecoverDuration * 0.5f, DeltaTime);
		else
			ToTargetAlpha.Velocity -= ToTargetAlpha.Velocity * 0.8f * DeltaTime;
		FVector Destination = FMath::Lerp(Owner.ActorLocation + ReturnRot.Value.Vector() * 1000.f, TargetLoc, ToTargetAlpha.Value);
        BehaviourComponent.MoveTo(Destination, Settings.RecoverAcceleration);
        BehaviourComponent.RotateTowards(Owner.ActorLocation + ReturnRot.Value.Vector() * 1000.f);

        if (HasReturned(DeltaTime))
		{
			UHazeAkComponent AudioComp = UHazeAkComponent::Get(Owner);
			AudioComp.HazePostEvent(HomingComp.StopFlyingEvent);
            BehaviourComponent.State = EWaspState::Idle;
		}
    }

	FVector GetTargetLocation()
	{
		// The prediction is not really relevant when moving away from target, but will suffice 
		FVector ReturnLoc = HomingComp.Launcher.WorldLocation;
		float PredictionTime = FMath::Max(0.f, 0.5f * (Owner.ActorLocation.Distance(ReturnLoc) / Owner.ActualVelocity.Size()) - 0.5f); 
		return ReturnLoc + (HomingComp.Wielder.ActualVelocity * PredictionTime);
	}

	bool HasReturned(float DeltaTime)
	{
		FVector DeltaMove = Owner.ActualVelocity * DeltaTime;
		FVector ReturnLoc = HomingComp.Launcher.WorldLocation;
		FVector ProjectedLoc;
		float FractionDummy;
		if (!Math::ProjectPointOnLineSegment(Owner.ActorLocation, Owner.ActorLocation + DeltaMove, ReturnLoc, ProjectedLoc, FractionDummy))
			return false;
		if (!ProjectedLoc.IsNear(ReturnLoc, 400.f))
			return false;
		return true;
	}
}

