import Cake.LevelSpecific.Tree.BeetleRiding.TreeBeetleRidingComponent;
import Cake.LevelSpecific.Tree.BeetleRiding.TreeBeetleRidingBeetle;
import Peanuts.Outlines.Outlines;

class UTreeBeetleRidingCameraCapability : UHazeCapability
{
	default CapabilityDebugCategory = n"BeetleRiding";

	default CapabilityTags.Add(n"BeetleRiding");

	default TickGroup = ECapabilityTickGroups::AfterPhysics;

	UTreeBeetleRidingComponent BeetleRidingComponent;
	AHazePlayerCharacter Player;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		BeetleRidingComponent = UTreeBeetleRidingComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(BeetleRidingComponent.Beetle == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(!BeetleRidingComponent.Beetle.bIsRunning)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(BeetleRidingComponent.Beetle == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		BeetleRidingComponent.Beetle.InitializeCamera();

		FHazeCameraBlendSettings BlendSettings;
		Player.ActivateCamera(BeetleRidingComponent.Beetle.Camera, BlendSettings, this);
		Player.ApplyViewSizeOverride(this, EHazeViewPointSize::Fullscreen);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float IdealDistance = BeetleRidingComponent.Beetle.SplineFollowerComponent.GetSplineTransform().Scale3D.Y * BeetleRidingComponent.Beetle.SplineFollowerComponent.Spline.BaseWidth;

		FHazeCameraBlendSettings BlendSettings;
		BlendSettings.BlendTime = 3.f;
	
		if (Player.GetCurrentlyUsedCamera().Owner == BeetleRidingComponent.Beetle)
		{
			FRotator Rot = Player.GetCurrentlyUsedCamera().WorldRotation;
			Rot.Roll = BeetleRidingComponent.Beetle.Camera.WorldRotation.Roll;
			Player.GetCurrentlyUsedCamera().WorldRotation = Rot; 
		}
	
	//	Player.ApplyIdealDistance(IdealDistance * 0.8f, BlendSettings);

		// FORCE CAMERA ROTATION TO FOLLOW SPLINE
	//	Player.GetCurrentlyUsedCamera().SetWorldRotation(BeetleRidingComponent.Beetle.SplineFollowerComponent.GetSplineTransform().Rotator());
	}
}