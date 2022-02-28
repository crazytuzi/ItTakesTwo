import Cake.LevelSpecific.Tree.Wasps.Behaviours.WaspBehaviourComponent;
import Cake.LevelSpecific.Tree.Wasps.Attacks.PlayerResponses.WaspAttackRunHitResponseCapability;
import Cake.LevelSpecific.Tree.Wasps.Settings.WaspComposableSettings;
import Cake.LevelSpecific.Tree.Wasps.Effects.WaspEffectsComponent;

class UWaspEffectAttackRunDecalCapability : UHazeCapability
{
	default CapabilityTags.Add(n"WaspEffects");

	default TickGroup = ECapabilityTickGroups::PostWork;

	UWaspBehaviourComponent BehaviourComp;
	UWaspEffectsComponent EffectsComp;
	UDecalComponent DecalComp;
	UWaspComposableSettings Settings;

	FHazeAcceleratedVector DecalPivot;
	FHazeAcceleratedRotator DecalRotation;
	FHazeAcceleratedFloat DecalLength;

	FVector PreviousAttackDest = FVector(BIG_NUMBER);

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		BehaviourComp = UWaspBehaviourComponent::Get(Owner);
		EffectsComp = UWaspEffectsComponent::Get(Owner);
		DecalComp = UDecalComponent::Get(Owner);
		DecalComp.DetachFromParent();
		Settings = UWaspComposableSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		// This capability runs locally. DisplayAttackDirection is replicated by 
		// net sync capability since it changes in runtime on control side. 
		if (!EffectsComp.ShouldShowAttackEffect())
			return EHazeNetworkActivation::DontActivate;
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!EffectsComp.ShouldShowAttackEffect())
            return EHazeNetworkDeactivation::DeactivateLocal;
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		PreviousAttackDest = FVector(BIG_NUMBER);
		FTransform TargetTransform = GetTargetDecalTransform();
		DecalLength.SnapTo(TargetTransform.GetScale3D().X);
		DecalPivot.SnapTo(TargetTransform.GetLocation());
		DecalRotation.SnapTo(TargetTransform.Rotator());
		DecalComp.SetWorldTransform(FTransform(DecalRotation.Value, DecalPivot.Value, FVector(DecalLength.Value, 5.f, 1.f)));		
		DecalComp.SetVisibility(true);
    }

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		DecalComp.SetVisibility(false);
    }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		FTransform TargetTransform = GetTargetDecalTransform();
		DecalLength.AccelerateTo(TargetTransform.GetScale3D().X, 0.5f, DeltaSeconds);
		DecalPivot.AccelerateTo(TargetTransform.GetLocation(), 0.5f, DeltaSeconds);
		DecalRotation.AccelerateTo(TargetTransform.Rotator(), 0.5f, DeltaSeconds);
		
		// Note that length is applied on Z, not X, since decal is rotated 90 degrees		
		FVector Scale = FVector(10.f, Settings.AttackRunDecalWidth, DecalLength.Value);
		DecalComp.SetWorldTransform(FTransform(DecalRotation.Value, DecalPivot.Value, Scale)); 
	}

	FTransform GetTargetDecalTransform()
	{
		float Length = 10.f;
		FRotator DecalRot = Owner.GetActorRotation();
		FVector AttackDest = EffectsComp.GetDisplayedAttackDestination();
		FVector PivotDest = AttackDest;
		if (BehaviourComp.HasValidTarget())
		{
			AHazeActor Target = BehaviourComp.GetTarget();
			FVector ToDest2D = AttackDest - Owner.ActorLocation;
			ToDest2D.Z = 0.f;
			float Dist2D = ToDest2D.Size2D();
			Length = FMath::Clamp(Dist2D * 0.005f, 1.f, 10.f);

			// Only change rotation when we're updating destination (e.g not when we've flown over target)
			if (FVector2D(PreviousAttackDest).Equals(FVector2D(AttackDest), 1.f))
				DecalRot = DecalRotation.Value;
			else
			{
				// We're still updating attack destination, may change rotation
				PreviousAttackDest = AttackDest;
				DecalRot = ToDest2D.Rotation();
				DecalRot.Pitch = 90.f; // Red arrow decal is rotated 90 degrees for some reason
				DecalRot.Roll = 0.f;
			}

			PivotDest = AttackDest - ToDest2D.GetSafeNormal2D() * Length * 200.f;
			PivotDest.Z = Target.GetActorLocation().Z + 100.f;
		}
		return FTransform(DecalRot, PivotDest, FVector(Length, 1.f, 1.f));
	}
};
