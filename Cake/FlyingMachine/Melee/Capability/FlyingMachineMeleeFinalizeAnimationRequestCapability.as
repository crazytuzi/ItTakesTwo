
import Cake.FlyingMachine.Melee.FlyingMachineMeleeComponent;


class UFlyingMachineMeleeFinalizeAnimationRequestCapability : UHazeMelee2DCapabilityBase
{
	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 200;

	default CapabilityDebugCategory = MeleeTags::Melee;

	AHazeCharacter CharacterOwner;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		CharacterOwner = Cast<AHazeCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{	
		if(!CharacterOwner.Mesh.CanRequestLocomotion())
			return EHazeNetworkActivation::DontActivate;	

		return EHazeNetworkActivation::ActivateLocal;	
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!CharacterOwner.Mesh.CanRequestLocomotion())
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(const FCapabilityActivationParams& ActivationParams)
	{		
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{			
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeRequestLocomotionData AnimationRequest;
		AnimationRequest.AnimationTag = MeleeComponent.AnimationRequest;
		AnimationRequest.LocomotionAdjustment.DeltaTranslation = MeleeComponent.GetHorizontalDeltaMove();
		AnimationRequest.LocomotionAdjustment.WorldRotation = CharacterOwner.GetActorQuat();
		AnimationRequest.WantedVelocity = AnimationRequest.LocomotionAdjustment.DeltaTranslation / DeltaTime;
		AnimationRequest.WantedWorldTargetDirection = AnimationRequest.WantedVelocity;
		AnimationRequest.WantedWorldFacingRotation = AnimationRequest.LocomotionAdjustment.WorldRotation;
		CharacterOwner.RequestLocomotion(AnimationRequest);

		// FHazeLocomotionTransform RootMotionTransform;
		// CharacterOwner.RequestRootMotion(DeltaTime, RootMotionTransform);
		// if(RootMotionTransform.DeltaTranslation.Size() > 0)
		// {
		// 	int Debug = 0;
		// }
		// //MeleeComponent.ActivateHorizontalTranslation(RootMotionTransform.DeltaTranslation.Size(), 0);
	}

	UFUNCTION(BlueprintOverride)
	FString GetDebugString()
	{
		FString Str = "";
		return Str;	
	}
}
