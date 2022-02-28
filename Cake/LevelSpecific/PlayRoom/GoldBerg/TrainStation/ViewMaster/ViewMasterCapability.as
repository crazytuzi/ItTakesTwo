import Cake.LevelSpecific.PlayRoom.GoldBerg.TrainStation.ViewMaster.ViewMasterActor;
import Peanuts.Fades.FadeStatics;
import Peanuts.Audio.AudioStatics;
import Peanuts.Foghorn.FoghornStatics;

class UViewMasterCapability : UHazeCapability
{
	AHazePlayerCharacter Player;
	AViewMasterActor ViewMaster;
	float UpFOV = 0;

	UPROPERTY()
	FText ZoomTextT;

	UPROPERTY()
	UFoghornVOBankDataAssetBase FoghornDatabase;

	UPROPERTY()
	FText LookTextT;

	bool bPlayedBark = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (GetAttributeObject(n"ViewMaster") != nullptr)
		{
			return EHazeNetworkActivation::ActivateFromControl;
		}
		else
		{
			return EHazeNetworkActivation::DontActivate;
		}
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& Params)
	{
		ViewMaster = Cast<AViewMasterActor>(GetAttributeObject(n"ViewMaster"));
		Params.AddObject(n"ViewMaster", ViewMaster);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		ViewMaster = Cast<AViewMasterActor>(ActivationParams.GetObject(n"ViewMaster"));
		
		if(HasControl())
		{
			ViewMaster.NetSetOwningPlayer(Player);
		}

		UpFOV = 0.f;
		ViewMaster.ZoomSync.Value = 0.f;
		FadeOutPlayer(Player, 0.1f, 0.1f, 0.1f);
		System::SetTimer(this, n"ActivateCamera", 0.15, false);

		FTutorialPrompt Prompt;
		Prompt.Text = ZoomTextT;
		Prompt.DisplayType = ETutorialPromptDisplay::LeftStick_UpDown;
		Prompt.MaximumDuration = 6;
		Prompt.Mode = ETutorialPromptMode::Default;
		ShowTutorialPrompt(Player, Prompt, this);
	}

	UFUNCTION()
	void ActivateCamera()
	{
		ViewMaster.Camera.ActivateCamera(Player, ViewMaster.CameraSettings, this);
		HazeAudio::SetPlayerPanning(ViewMaster.HazeAkComp, Player);
		ViewMaster.HazeAkComp.HazePostEvent(ViewMaster.PlayMovementAudioEvent);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HasControl())
		{
			ViewMaster.ZoomSync.Value = UpFOV;
			UpFOV += DeltaTime * GetAttributeVector(AttributeVectorNames::LeftStickRaw).Y * -40;
			UpFOV = FMath::Clamp(UpFOV, -20.f, 20.f);
		}
		else
		{
			UpFOV = ViewMaster.ZoomSync.Value;
		}

		Player.ApplyFieldOfView(UpFOV, CameraBlend::Additive(0.f), this, EHazeCameraPriority::High);

		float NormalizedZoom = HazeAudio::NormalizeRTPC01(FMath::Abs(Player.ViewFOVVelocity), 0.f, 36.f);
		float NormalizedPan = HazeAudio::NormalizeRTPC01(FMath::Abs(Player.ViewAngularVelocity.Yaw), 0.f, 36.f);
		float NormalizedTilt = HazeAudio::NormalizeRTPC01(FMath::Abs(Player.ViewAngularVelocity.Pitch), 0.f, 12.f);
			
		ViewMaster.HazeAkComp.SetRTPCValue("Rtpc_World_SideContent_Playroom_Interaction_Binoculars_Zoom", NormalizedZoom);
		ViewMaster.HazeAkComp.SetRTPCValue("Rtpc_World_SideContent_Playroom_Interaction_Binoculars_Pan", NormalizedPan);
		ViewMaster.HazeAkComp.SetRTPCValue("Rtpc_World_SideContent_Playroom_Interaction_Binoculars_Tilt", NormalizedTilt);

		FVector DirToCutie = ViewMaster.Cutie.ActorLocation - ViewMaster.Camera.ActorLocation;
		DirToCutie.Normalize();
		float DotToCutie = DirToCutie.DotProduct(Player.ViewRotation.ForwardVector);
		if (HasControl() && DotToCutie >= 0.995f && !bPlayedBark)
			NetPlayBark();
	}

	UFUNCTION(NetFunction)
	void NetPlayBark()
	{
		bPlayedBark = true;
		if (Player.IsCody())
			PlayFoghornVOBankEvent(FoghornDatabase, n"FoghornDBPlayRoomTrainStationTelescopeCutieCody");
		else
			PlayFoghornVOBankEvent(FoghornDatabase, n"FoghornDBPlayRoomTrainStationTelescopeCutieMay");
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (Player.HasControl() && GetAttributeObject(n"ViewMaster") == nullptr)
		{
			return EHazeNetworkDeactivation::DeactivateFromControl;
		}
		else
		{
			return EHazeNetworkDeactivation::DontDeactivate;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		FadeOutPlayer(Player, 0.1f, 0.1f, 0.1f);
		System::SetTimer(this, n"ResetCamera", 0.15f, false);
		RemoveTutorialPromptByInstigator(Player, this);
		ViewMaster.HazeAkComp.HazePostEvent(ViewMaster.StopMovementAudioEvent);
	}

	UFUNCTION()
	void ResetCamera()
	{
		ViewMaster.Camera.DeactivateCamera(Player, 0);
		Player.ClearFieldOfViewByInstigator(this, 0);
		Player.SnapCameraBehindPlayer();
	}
}