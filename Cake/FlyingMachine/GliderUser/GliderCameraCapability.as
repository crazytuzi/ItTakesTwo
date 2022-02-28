import Cake.FlyingMachine.Glider.FlyingMachineGliderComponent;
import Cake.FlyingMachine.Glider.FlyingMachineGlider;
import Cake.FlyingMachine.FlyingMachineNames;
import Vino.Camera.Components.CameraUserComponent;
import Vino.Camera.Capabilities.CameraTags;

class UFlyingMachineGliderCameraCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(FlyingMachineTag::Glider);
	default CapabilityTags.Add(FlyingMachineTag::Camera);
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 105;
	default CapabilityDebugCategory = FlyingMachineCategory::Glider;
	
	AHazePlayerCharacter Player;
	UFlyingMachineGliderUserComponent GliderUser;

	AFlyingMachineGlider Glider;
	UFlyingMachineGliderComponent GliderComp;

	UCameraUserComponent CameraUser;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		GliderUser = UFlyingMachineGliderUserComponent::GetOrCreate(Owner);
		CameraUser = UCameraUserComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (GliderUser.Glider == nullptr)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		GliderComp = GliderUser.Glider;
		Glider = Cast<AFlyingMachineGlider>(GliderComp.GetOwner());

		FHazeCameraBlendSettings Blend;
		Blend.BlendTime = 1.5f;
		Player.ApplySettings(Glider.CameraChaseSettings, this, EHazeSettingsPriority::Gameplay);
		Player.ApplyCameraSettings(Glider.CameraSettings, Blend, this, EHazeCameraPriority::Low);
		Player.ActivateCamera(Glider.Camera, Blend, this, EHazeCameraPriority::Low);

		Owner.BlockCapabilities(CameraTags::Control, this);
		Owner.BlockCapabilities(CameraTags::CameraReplication, this);
		Owner.BlockCapabilities(n"CameraNonControlled", this);

		// Camera is not controlled during glider (only controlled by vehicle chase) so will work better
		// if locally simulated. Might fix NUTS-8158.
		Player.BlockCameraSyncronization(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.DeactivateCameraByInstigator(this);
		Player.ClearCameraSettingsByInstigator(this);
		Player.ClearSettingsByInstigator(this);
		Owner.UnblockCapabilities(CameraTags::Control, this);
		Owner.UnblockCapabilities(CameraTags::CameraReplication, this);
		Owner.UnblockCapabilities(n"CameraNonControlled", this);

		Player.UnblockCameraSyncronization(this);
	}
}