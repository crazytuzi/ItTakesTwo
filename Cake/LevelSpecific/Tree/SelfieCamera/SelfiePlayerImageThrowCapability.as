import Cake.LevelSpecific.Tree.SelfieCamera.SelfiePlayerImageComponent;
import Cake.LevelSpecific.Tree.SelfieCamera.SelfieCameraImage;
import Vino.Camera.Components.CameraUserComponent;
import Cake.LevelSpecific.Tree.SelfieCamera.SelfieImageThrowCameraManager;
import Vino.PlayerHealth.PlayerHealthStatics;

class USelfiePlayerImageThrowCapability : UHazeCapability
{
	default CapabilityTags.Add(n"SelfiePlayerImageThrowCapability");
	default CapabilityTags.Add(n"SelfieCamera");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	USelfiePlayerImageComponent PlayerComp;
	ASelfieCameraImage Image;
	UCameraUserComponent UserComp;

	bool bCanTimer;
	bool bActive;

	float DefaultTimer = 1.7f;
	float CurrentTimer;

	FHazeAcceleratedRotator AccelRot;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		UserComp = UCameraUserComponent::Get(Player);
		bActive = true;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        if (bActive)
			return EHazeNetworkActivation::ActivateUsingCrumb;
		
		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
        if (!bActive)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(CapabilityTags::Interaction, this);
		Player.BlockCapabilities(n"Death", this);
		Player.TriggerMovementTransition(this);

		PlayerComp = USelfiePlayerImageComponent::Get(Player);

		FHazeAnimationDelegate OnBlendIn;
		FHazeAnimationDelegate OnBlendOut;
		OnBlendOut.BindUFunction(this, n"AnimFinishedBlendToIdle");
		
		Player.PlaySlotAnimation(OnBlendIn, OnBlendOut, PlayerComp.ThrowAnimation[Player], false);
		
		System::SetTimer(this, n"AttachImage", 0.83f, false);

		Image = Cast<ASelfieCameraImage>(PlayerComp.ImageRef);

		AccelRot.SnapTo(UserComp.DesiredRotation);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(CapabilityTags::Interaction, this);
		Player.UnblockCapabilities(n"Death", this);
		
		PlayerComp.OnSelfieThrowAnimCompleteEvent.Broadcast(Player);
		Player.StopAllSlotAnimations(0.5f);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (bCanTimer)
		{
			CurrentTimer -= DeltaTime;

			FVector Direction = Image.ActorLocation - (Player.ActorLocation + FVector(0.f, 0.f, 200.f));
			Direction.Normalize();
			FRotator DesiredRot = FRotator::MakeFromX(Direction);
			AccelRot.AccelerateTo(DesiredRot, 1.f, DeltaTime);
			UserComp.SetDesiredRotation(AccelRot.Value);

			if (CurrentTimer <= 0.f)
			{
				bCanTimer = false;
				bActive = false;
			}
		}
	}

	UFUNCTION()
	void AttachImage()
	{
		System::SetTimer(this, n"ReleaseImage", 0.6f, false);
		Image.AttachToActor(Player, n"LeftAttach", EAttachmentRule::KeepWorld);
		// Image.AttachToActor(Player, n"LeftAttach", EAttachmentRule::SnapToTarget);
		// Image.ActorLocation += Image.ActorForwardVector * 150.f;
		// FRotator CorrectionRot = FRotator(Image.ActorRotation.Pitch, Image.ActorRotation.Yaw + 180.f, Image.ActorRotation.Roll);
		// Image.SetActorRotation(CorrectionRot);
	}

	UFUNCTION()
	void ReleaseImage()
	{
		Image.DetachFromActor(EDetachmentRule::KeepWorld);
		Image.ThrowImage();
		CurrentTimer = DefaultTimer;
		bCanTimer = true;
	}

	UFUNCTION()
	void AnimFinishedBlendToIdle()
	{
		Player.PlaySlotAnimation(Animation = PlayerComp.IdleAnim[Player], bLoop = true, BlendTime = 0.5f);
	}
}