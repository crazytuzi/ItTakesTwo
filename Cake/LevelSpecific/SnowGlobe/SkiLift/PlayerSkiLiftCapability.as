import Cake.LevelSpecific.SnowGlobe.SkiLift.SkiLift;
import Vino.Movement.Components.MovementComponent;

class UPlayerSkiLiftCapability : UHazeCapability
{
	default CapabilityTags.Add(n"LevelSpecific");
	default CapabilityTags.Add(n"SnowglobeSkiLift");

	default TickGroup = ECapabilityTickGroups::ActionMovement;

	default CapabilityDebugCategory = n"LevelSpecific";

	UPROPERTY()
	UHazeLocomotionFeatureBase SkiLiftLocomotionCody;

	UPROPERTY()
	UHazeLocomotionFeatureBase SkiLiftLocomotionMay;

	AHazePlayerCharacter PlayerOwner;
	UHazeLocomotionFeatureBase SkiLiftLocomotion;

	ASkiLift SkiLift;

	const float ExitDuration = 1.3333f;
	float ElapsedExitTime;

	bool bExiting;
	bool bDoneExiting;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		SkiLiftLocomotion = PlayerOwner.IsCody() ? SkiLiftLocomotionCody : SkiLiftLocomotionMay;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(GetAttributeObject(n"SkiLift") == nullptr)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		PlayerOwner.BlockCapabilities(CapabilityTags::Movement, this);
		PlayerOwner.BlockCapabilities(n"PlayerShadow", this);
		PlayerOwner.TriggerMovementTransition(this, n"SkiLiftStart");

		// Get skilift and attach player to it
		SkiLift = Cast<ASkiLift>(GetAttributeObject(n"SkiLift"));
		PlayerOwner.AttachToComponent(SkiLift.Mesh, SkiLift.GetAttachSocketNameForPlayer(PlayerOwner));

		// Add skilift locomotion feature
		PlayerOwner.AddLocomotionFeature(SkiLiftLocomotion);

		// Add camera settings
		PlayerOwner.ApplyCameraSettings(SkiLift.SpringArmSettings, 0.f, this);

		// Setup delegates
		SkiLift.OnSkiLiftExitEvent.AddUFunction(this, n"OnSkiLiftExit");
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Apply camera offset
		FVector CameraOffsetOwnerSpace = PlayerOwner.IsCody() ? FVector(-300.f,-150.f, 300.f) : FVector(-300.f, 65.f, 300.f);
		PlayerOwner.ApplyCameraOffsetOwnerSpace(CameraOffsetOwnerSpace, 0.f, this);

		if(bExiting)
		{
			ElapsedExitTime += DeltaTime;
			if(ElapsedExitTime >= ExitDuration)
			{
				bDoneExiting = true;
				return;
			}
		}

		// Request locomotion
		FHazeRequestLocomotionData LocomotionRequest;
		LocomotionRequest.AnimationTag = n"SkiLift";
		PlayerOwner.RequestLocomotion(LocomotionRequest);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(bDoneExiting)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		PlayerOwner.UnblockCapabilities(CapabilityTags::Movement, this);
		PlayerOwner.UnblockCapabilities(n"PlayerShadow", this);

		// Detach from ski lift and remove locomtion feature
		PlayerOwner.DetachRootComponentFromParent();
		PlayerOwner.RemoveLocomotionFeature(SkiLiftLocomotion);

		// Remove camera settings
		PlayerOwner.ClearCameraSettingsByInstigator(this);

		// Maintain exit animation momentum
		FVector Velocity = -PlayerOwner.MovementWorldUp * 620.f;
		PlayerOwner.MovementComponent.SetVelocity(Velocity);

		// *knock knock kock* house keeping!
		ElapsedExitTime = 0.f;
		bExiting = false;
		bDoneExiting = false;
	}

	UFUNCTION(NotBlueprintCallable)
	void OnSkiLiftExit()
	{
		bExiting = true;
		ElapsedExitTime = 0.f;
		PlayerOwner.SetAnimBoolParam(n"ExitSkiLift", true);

		// Clear blackboard
		UObject SkiLiftObject;
		ConsumeAttribute(n"SkiLift", SkiLiftObject);
		SkiLiftObject = nullptr;
	}
}