import Cake.LevelSpecific.PlayRoom.GoldBerg.RailCart.Names;
import Cake.LevelSpecific.PlayRoom.GoldBerg.RailCart.RailPumpCartUserComponent;
import Effects.PostProcess.PostProcessing;

class URailPumpCartUserCameraCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(RailCartTags::Cart);
	default CapabilityTags.Add(RailCartTags::User);
	default CapabilityTags.Add(RailCartTags::Camera);
	default CapabilityTags.Add(CameraTags::VehicleChaseAssistance);

	default CapabilityDebugCategory = CameraTags::Camera;

	default TickGroup = ECapabilityTickGroups::GamePlay;

	AHazePlayerCharacter Player;
	URailPumpCartUserComponent CartUser;
	UCameraUserComponent CameraUser;
	UPostProcessingComponent PostProcessingComp;

	ARailPumpCart Cart;

	const float PredictDistance = 500.f;

	FHazeAcceleratedRotator CameraRotation;
	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		CartUser = URailPumpCartUserComponent::GetOrCreate(Player);
		CameraUser = UCameraUserComponent::Get(Player);
		PostProcessingComp = UPostProcessingComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (CartUser.CurrentCart == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if (!CartUser.CurrentCart.AreBothPlayersOnCart())
			return EHazeNetworkActivation::DontActivate;

		if (CartUser.CurrentCart.bIsLocked)
			return EHazeNetworkActivation::DontActivate;

		// In first segment (trainstation -> dinoland) May should get full screen from this capability
		// In second (Dino -> Pirate) Cody gets fullscreen from script, so need to activate this as well.
		if (CartUser.bFront && !Player.IsPendingFullscreen())
		  	return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (CartUser.CurrentCart == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (!CartUser.CurrentCart.AreBothPlayersOnCart())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (CartUser.CurrentCart.bIsLocked)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams Params)
	{
		Cart = CartUser.CurrentCart;

		FHazeCameraBlendSettings Blend;
		Blend.BlendTime = 2.f;

		Player.ActivateCamera(Cart.Camera, Blend, this);

		if (!Player.OtherPlayer.IsPendingFullscreen())
			Player.ApplyViewSizeOverride(this, EHazeViewPointSize::Fullscreen, EHazeViewPointBlendSpeed::Normal, EHazeViewPointPriority::Gameplay);
		Player.BlockCapabilities(CameraTags::Control, this);
		Player.BlockCapabilities(CameraTags::NonControlled, this);
		Player.BlockCameraSyncronization(this);

		CameraRotation.SnapTo(CameraUser.DesiredRotation);
		PostProcessingComp.DisableOutlineByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams Params)
	{
		Player.DeactivateCameraByInstigator(this);

		Player.ClearViewSizeOverride(this, EHazeViewPointBlendSpeed::Normal);
		Player.UnblockCapabilities(CameraTags::Control, this);
		Player.UnblockCapabilities(CameraTags::NonControlled, this);
		Player.UnblockCameraSyncronization(this);
		PostProcessingComp.EnableOutlineByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Do some turn prediction
		FHazeSplineSystemPosition Position = Cart.SplineFollow.GetPosition();
		Position.Move(Cart.Speed * 0.4f);

		FRotator TargetRotation = Math::MakeRotFromX(Position.WorldForwardVector);
		TargetRotation.Pitch -= 20.f;

		CameraRotation.AccelerateTo(TargetRotation, 2.f, DeltaTime);
		CameraUser.DesiredRotation = CameraRotation.Value;
	}
}