import Cake.LevelSpecific.SnowGlobe.Swimming.AI.AnglerFish.Behaviours.FishBehaviourComponent;
import Cake.LevelSpecific.SnowGlobe.Swimming.AI.AnglerFish.Settings.FishComposableSettings;
import Vino.Camera.Components.CameraSpringArmComponent;
import Peanuts.Fades.FadeStatics;
import Cake.LevelSpecific.SnowGlobe.Swimming.AI.AnglerFish.Effects.FishEffectsComponent;

class UFishLungeCameraCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Attack");
	default TickGroup = ECapabilityTickGroups::PostWork;

	UFishBehaviourComponent BehaviourComp;
	UFishEffectsComponent EffectsComp;
	UFishComposableSettings Settings;
	UHazeCameraComponent Camera = nullptr;
	float EndTime = 0.f;
	AHazePlayerCharacter Player = nullptr;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		BehaviourComp = UFishBehaviourComponent::Get(Owner);
		EffectsComp = UFishEffectsComponent::Get(Owner);
		Settings = UFishComposableSettings::GetSettings(Owner);
		ensure((BehaviourComp != nullptr) && (Settings != nullptr));
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (BehaviourComp.State != EFishState::Attack)
			return EHazeNetworkActivation::DontActivate;
		if (!IsGoodTarget(BehaviourComp.Target))
			return EHazeNetworkActivation::DontActivate;
		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	bool IsGoodTarget(AHazeActor Target) const
	{
		if (Target == nullptr)
			return false;
		if (!Target.IsA(AHazePlayerCharacter::StaticClass()))
			return false;
		// Should wait with deactivating camera until we're close		
		// if (!Owner.ActorLocation.IsNear(Target.ActorLocation, 6000.f))
		// 	return false;
		// Must also be in front of us
		// FVector ToTargetDir = (Target.ActorLocation - Owner.ActorLocation).GetSafeNormal();
		// if (BehaviourComp.MawForwardVector.DotProduct(ToTargetDir) < 0.866)
		// 	return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (Time::GetGameTimeSeconds() > EndTime)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		EndTime = Time::GetGameTimeSeconds() + 2.f;
		//System::SetTimer(this, n"FadeScreen", 1.f, false);
		Player = Cast<AHazePlayerCharacter>(BehaviourComp.Target);

		// TODO: Move camera to BP and fetch it from there if we want to go with this
		// if (Camera == nullptr)
		// {
		// 	UCameraSpringArmComponent SpringArm = UCameraSpringArmComponent::Create(Owner);
		// 	SpringArm.AttachTo(Owner.RootComponent, NAME_None, EAttachLocation::SnapToTarget);
		// 	Camera = UHazeCameraComponent::Create(Owner);
		// 	Camera.AttachTo(SpringArm, NAME_None, EAttachLocation::SnapToTarget);
		// }

		//FHazeCameraBlendSettings Blend = FHazeCameraBlendSettings(0.5f);
		// Player.ApplyCameraSettings(BehaviourComp.LungeCameraSettings, Blend, this, EHazeCameraPriority::High);
		// Player.ActivateCamera(Camera, Blend, this, EHazeCameraPriority::High);

		// FHazePointOfInterest POI;	
		// POI.FocusTarget.Actor = Owner;
		// POI.FocusTarget.LocalOffset = FVector(0.f, 0.f, -2000.f);
		// POI.Blend.BlendTime = 0.2f;
		//Player.ApplyPointOfInterest(POI, this, EHazeCameraPriority::High);

		if (EffectsComp.MawCamera != nullptr)
		{
			float CosAngle = Player.GetPlayerViewRotation().Vector().DotProduct(Owner.ActorForwardVector);
			if (CosAngle > 0.5f)
				Player.ActivateCamera(EffectsComp.MawCamera, FHazeCameraBlendSettings(0.2f), this);
		}
 	}

	// UFUNCTION()
	// void FadeScreen()
	// {
	// 	if (IsActive())
	// 		FadeOutPlayer(Player, 3.f, 1.f, 1.f);
	// }

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.DeactivateCameraByInstigator(this);
		Player.ClearPointOfInterestByInstigator(this);
		Player.ClearCameraSettingsByInstigator(this);
	}	
}