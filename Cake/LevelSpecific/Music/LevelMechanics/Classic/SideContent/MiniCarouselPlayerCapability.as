import Cake.LevelSpecific.Music.LevelMechanics.Classic.SideContent.MiniCarousel;
import Vino.Tutorial.TutorialPrompt;
import Vino.Tutorial.TutorialStatics;
import Vino.Camera.Settings.CameraLazyChaseSettings;

class PlayerMiniCarouselCapability : UHazeCapability
{
	default CapabilityTags.Add(n"MiniCarouselCapability");
	default CapabilityDebugCategory = n"MiniCarousel";
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 100;

	AHazePlayerCharacter MyPlayer;
	AMiniCarosuel MiniCarosuel;
	UInteractionComponent Interaction;
	UHazeCameraComponent Camera;
	USceneComponent JumpOffLocation;

	float TimeSpentOnCarosuel = 0;
	bool bVOHorseLongTimePlayed = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		MyPlayer = Cast<AHazePlayerCharacter>(Owner);	
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		AMiniCarosuel CarouselLocal = Cast<AMiniCarosuel>(GetAttributeObject(n"Carousel"));
		if(CarouselLocal == nullptr)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateFromControl;
	}


	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(WasActionStarted(ActionNames::Cancel))
		{
			return EHazeNetworkDeactivation::DeactivateFromControl;
		}

		return EHazeNetworkDeactivation::DontDeactivate;
	}


	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		MiniCarosuel = Cast<AMiniCarosuel>(GetAttributeObject(n"Carousel"));
		Interaction = Cast<UInteractionComponent>(GetAttributeObject(n"Interaction"));
		//Camera = Cast<UHazeCameraComponent>(GetAttributeObject(n"CameraHorse"));
		JumpOffLocation = Cast<USceneComponent>(GetAttributeObject(n"JumpOffLocation"));
		MyPlayer.ApplyCameraSettings(MiniCarosuel.CameraSetting, 2.5f, this, EHazeCameraPriority::High);
		//MyPlayer.ActivateCamera(Camera, FHazeCameraBlendSettings(5.f), this, EHazeCameraPriority::Maximum);

		FTutorialPrompt CancelPrompt;
		CancelPrompt.Action = ActionNames::Cancel;
		CancelPrompt.DisplayType = ETutorialPromptDisplay::Action;
		CancelPrompt.Text = MiniCarosuel.CancelText;
		ShowTutorialPrompt(MyPlayer, CancelPrompt, MyPlayer);

		if(MyPlayer == Game::GetCody())
		{
			FHazeAnimationDelegate OnBlendedIn;
			FHazeAnimationDelegate OnBlendingOut;
			MyPlayer.PlayEventAnimation(OnBlendedIn, OnBlendingOut, MiniCarosuel.CodyMH, true, EHazeBlendType::BlendType_Inertialization, 0.4f);

			if(Game::GetCody().HasControl())
				MiniCarosuel.BroadCastCodyJumpedOnHorse();
		}
		else
		{
			FHazeAnimationDelegate OnBlendedIn;
			FHazeAnimationDelegate OnBlendingOut;
			MyPlayer.PlayEventAnimation(OnBlendedIn, OnBlendingOut, MiniCarosuel.MayMH, true, EHazeBlendType::BlendType_Inertialization, 0.4f);

			if(Game::GetMay().HasControl())
				MiniCarosuel.BroadCastMayJumpedOnHorse();
		}


		MyPlayer.BlockCapabilities(CapabilityTags::Movement, this);
		MyPlayer.TriggerMovementTransition(this);
		MyPlayer.BlockMovementSyncronization();
		MyPlayer.AttachToComponent(Interaction, NAME_None, EAttachmentRule::SnapToTarget);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if(MyPlayer == Game::GetCody())
			MyPlayer.StopAnimationByAsset(MiniCarosuel.CodyMH);
		else
			MyPlayer.StopAnimationByAsset(MiniCarosuel.MayMH);

		TimeSpentOnCarosuel = 0;
		//MyPlayer.DeactivateCamera(Camera, 1.25f);	

		MyPlayer.ClearCameraSettingsByInstigator(this);
		MyPlayer.ClearSettingsByInstigator(this);

		MyPlayer.RemoveTutorialPromptByInstigator(MyPlayer);


		MyPlayer.UnblockCapabilities(CapabilityTags::Movement, this);
		MyPlayer.UnblockMovementSyncronization();
		MyPlayer.DetachFromActor(EDetachmentRule::KeepWorld);
		MiniCarosuel.UnBlockAllInteractionsForPlayer(MyPlayer, Interaction);

		MyPlayer.SetCapabilityAttributeObject(n"Carousel", nullptr);
		MyPlayer.SetCapabilityAttributeObject(n"Interaction", nullptr);

		FHazeJumpToData JumpData;
		JumpData.AdditionalHeight = 150;
		JumpData.Transform = JumpOffLocation.GetWorldTransform();
		JumpTo::ActivateJumpTo(MyPlayer, JumpData);
	}


	
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if(GetAttributeVector2D(AttributeVectorNames::CameraDirection).Size() > 0.1f)
		{
			FRotator Rot =	MyPlayer.GetActorTransform().InverseTransformVector(MyPlayer.ViewRotation.Vector()).Rotation();
			//Rot = Rot.Compose(FRotator(0,30,0));
			UCameraLazyChaseSettings::SetChaseOffset(MyPlayer, Rot, this);
		}	

		if(MiniCarosuel.bMiniCarouselStarted == false)
			return;

		if(MyPlayer.HasControl())
		{
			if(bVOHorseLongTimePlayed == false)
			{
				TimeSpentOnCarosuel += DeltaTime;
				if(TimeSpentOnCarosuel >= 12)
				{
					bVOHorseLongTimePlayed = true;
					if(MyPlayer == Game::GetMay())
					{
						MiniCarosuel.BroadCastMayStayedOnHorseLong();
					}
					if(MyPlayer == Game::GetCody())
					{
						MiniCarosuel.BroadCastCodyStayedOnHorseLong();
					}
				}
			}
		}
	}
}