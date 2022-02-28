import Cake.LevelSpecific.Tree.Wasps.Behaviours.WaspBehaviourComponent;
import Cake.LevelSpecific.Tree.Wasps.Attacks.PlayerResponses.WaspAttackRunHitResponseCapability;
import Cake.LevelSpecific.Tree.Wasps.Settings.WaspComposableSettings;
import Cake.LevelSpecific.Tree.Wasps.Effects.WaspEffectsComponent;

class UWaspEffectFormationAttackDecalCapability : UHazeCapability
{
	default CapabilityTags.Add(n"WaspEffects");

	default TickGroup = ECapabilityTickGroups::PostWork;

	UWaspBehaviourComponent BehaviourComp;
	UWaspEffectsComponent EffectsComp;
	UDecalComponent DecalComp;

	FVector DecalPivot;
	FRotator DecalRotation;
	float DecalLength;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		BehaviourComp = UWaspBehaviourComponent::Get(Owner);
		EffectsComp = UWaspEffectsComponent::Get(Owner);
		DecalComp = UDecalComponent::Get(Owner);
		DecalComp.DetachFromParent();
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
		GetTargetDecalParameters(DecalPivot, DecalRotation, DecalLength);
		UWaspComposableSettings Settings = UWaspComposableSettings::GetSettings(Owner);
		FVector Scale = FVector(10.f, Settings.AttackRunDecalWidth, DecalLength);
		DecalComp.SetWorldTransform(FTransform(DecalRotation, DecalPivot, Scale));		
		DecalComp.SetVisibility(true);
		DecalComp.AttachToComponent(BehaviourComp.CurrentScenepoint, NAME_None, EAttachmentRule::KeepWorld);
    }

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		DecalComp.SetVisibility(false);
    }

	void GetTargetDecalParameters(FVector& Pivot, FRotator& Rotation, float& Length)
	{
		Rotation = Owner.GetActorRotation();
		FVector AttackDest = EffectsComp.GetDisplayedAttackDestination();

		FVector ToDest2D = AttackDest - Owner.ActorLocation;
		ToDest2D.Z = 0.f;
		float Dist2D = ToDest2D.Size2D();
		Length = FMath::Clamp(Dist2D * 0.004f, 1.f, 50.f);

		Rotation = ToDest2D.Rotation();
		Rotation.Pitch = 90.f; // Red arrow decal is rotated 90 degrees for some reason
		Rotation.Roll = 0.f;

		Pivot = Owner.ActorLocation;
		if (BehaviourComp.HasValidTarget())
			Pivot.Z = BehaviourComp.Target.ActorLocation.Z + 100.f;
	}
};
