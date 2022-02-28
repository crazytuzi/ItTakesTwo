import Cake.LevelSpecific.Tree.SelfieCamera.SelfieCameraActor;
import Cake.LevelSpecific.Tree.SelfieCamera.SelfieCameraPlayerComponent;
import Peanuts.Fades.FadeStatics;
import Cake.LevelSpecific.Tree.SelfieCamera.SelfieCameraWidget;
import Vino.Camera.Components.CameraUserComponent;

class USelfieCameraPlayerLookControlCapability : UHazeCapability
{
	default CapabilityTags.Add(n"SelfieCameraPlayerLookCapability");
	default CapabilityTags.Add(n"SelfieCamera");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	
	USelfieCameraPlayerComponent PlayerComp;

	float PlayerDefaultFov;
	float ZoomMaxFov = 60.f;
	float ZoomMinFov = 12.f;
	float FovTarget;

	float ZoomAdd = 0.f;
	float FovAdd = 16.f;

	float CurrentYaw;
	const float YawClamp = 12.f;
	float YawMin;
	float YawMax;
	float CurrentPitch;
	const float PitchClampMin = 3.f;
	const float PitchClampMax = 6.f;
	float PitchMin;
	float PitchMax;

	bool bCanStartFov;

	FHazeAcceleratedFloat AccelFov;
	FHazeAcceleratedFloat AccelYawRot;
	FHazeAcceleratedFloat AccelPitchRot;

	ASelfieCameraActor SelfieCamActor;
	UCameraUserComponent UserComp;
	
	// USelfieCameraWidget WidgetRef;

	float InputDividerYaw = 5.f;
	float InputDividerPitch = 8.f;

	float AudioRotationValue;
	float AudioPitchValue;
	float AudioYawValue;
	float AudioZoomValue;
	
	bool bIsZooming;
	bool bIsLooking;
	bool bIsYaw;
	bool bIsPitch;

	// float CurrentShowWidgetsTime;
	// float DefaultShowWidgetsTime = 0.75f;

//*** NETWORKING ***//
	float CurrentNetTime;
	float NetRate = 0.4f;
	float NetFovTarget;
	FHazeAcceleratedFloat NetAccelFov;

	float NetYawTarget;
	float NetPitchTarget;
	FHazeAcceleratedFloat NetFovYawRot;
	FHazeAcceleratedFloat NetFovPitchRot;

	float NetZoomAlpha;
	float NetZoomValue;
	FHazeAcceleratedFloat NetAccelZoomAlpha;
	FHazeAcceleratedFloat NetAccelZoomValue;

	float NetAudioRotationPitch;
	float NetAudioRotationYaw;
	float NetAudioZoom;
	FHazeAcceleratedFloat NetAccelAudioRotationPitch;
	FHazeAcceleratedFloat NetAccelAudioRotationYaw;
	FHazeAcceleratedFloat NetAccelAudioZoom;

	float RemoteAccelerationTime = 2.6f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		UserComp = Cast<UCameraUserComponent>(Player);

		PlayerComp = USelfieCameraPlayerComponent::Get(Player);
		PlayerComp.bCanLook = true;

		SelfieCamActor = GetSelfieCameraActor();

		Initialize();
	}

	UFUNCTION()
	void Initialize()
	{
		PlayerDefaultFov = Player.GetViewFOV();
		FovTarget = SelfieCamActor.CamFOV;
		
		FadeOutPlayer(Player, 0.5f, 0.32f, 0.42f); 
		Player.ApplyViewSizeOverride(this, EHazeViewPointSize::Large, EHazeViewPointBlendSpeed::Slow);

		FHazeCameraBlendSettings Blend;
		Blend.BlendTime = 1.f;
		SelfieCamActor.Camera.ActivateCamera(Player, Blend, this);

		NetFovTarget = FovTarget;
		NetAccelFov.SnapTo(FovTarget);
		AccelFov.SnapTo(FovTarget);
		SelfieCamActor.CamFOV = AccelFov.Value;

		bCanStartFov = true;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (PlayerComp.bCanLook)
			return EHazeNetworkActivation::ActivateUsingCrumb;
        
		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!PlayerComp.bCanLook)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.BlockCapabilities(n"Death", this);

		YawMin = SelfieCamActor.StartingYaw - YawClamp;
		YawMax = SelfieCamActor.StartingYaw + YawClamp;
		PitchMin = SelfieCamActor.StartingPitch - PitchClampMin;
		PitchMax = SelfieCamActor.StartingPitch + PitchClampMax;

		PlayerDefaultFov = Player.GetViewFOV();
		FovTarget = SelfieCamActor.CamFOV;
		
		if (HasControl())
		{
			CurrentYaw = SelfieCamActor.ActorRotation.Yaw;
			CurrentPitch = SelfieCamActor.ActorRotation.Pitch;

			AccelYawRot.SnapTo(CurrentYaw);
			AccelPitchRot.SnapTo(CurrentPitch);

			InitializeNetTargets(CurrentYaw, CurrentPitch, FovTarget);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.UnblockCapabilities(n"Death", this);
		PlayerComp.HidePlayerTakePic(Player);
		SelfieCamActor.AudioStopCameraRotation();				
		SelfieCamActor.AudioStopZoom();				
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		Player.ApplyViewSizeOverride(this, EHazeViewPointSize::Normal, EHazeViewPointBlendSpeed::Slow);

		PlayerComp.HidePlayerCancel(Player);

		FadeOutPlayer(Player, 0.5f, 0.25f, 0.5f); 
		
		SelfieCamActor.Camera.DeactivateCamera(Player, 1.5f);
		FHazeCameraBlendSettings Blend;
		Blend.BlendTime = 2.5f;

		Player.ApplyFieldOfView(PlayerDefaultFov, Blend, this);
		Player.ClearCameraSettingsByInstigator(this);
		bCanStartFov = false;

		SelfieCamActor.AudioStopCameraRotation();				
		SelfieCamActor.AudioStopZoom();				
		PlayerComp.bCanCancel = false;
	}

	UFUNCTION(NetFunction)
	void InitializeNetTargets(float AccelYaw, float AccelPitch, float InFovTarget)
	{
		if (!HasControl())
		{
			NetFovTarget = InFovTarget;
			NetYawTarget = AccelYaw;
			NetPitchTarget = AccelPitch;
			NetAccelFov.SnapTo(NetFovTarget);
			NetFovYawRot.SnapTo(NetYawTarget);
			NetFovPitchRot.SnapTo(NetPitchTarget);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (HasControl())
		{
			if (bCanStartFov)
				CameraZoomControl(DeltaTime);

			CameraRotationControl(DeltaTime);

			SelfieCamActor.SetActorRotation(FRotator(0.f, AccelYawRot.Value, 0.f));
			SelfieCamActor.CameraPivot.SetRelativeRotation(FRotator(AccelPitchRot.Value, 0.f, 0.f));

			CurrentNetTime -= DeltaTime;

			if (PlayerComp.WidgetRef != nullptr)
			{
				PlayerComp.WidgetRef.BP_SetZoomValue(GetFovAlpha());
				PlayerComp.WidgetRef.BP_SetZoomTextValue(GetFovZoomValue());
			}

			if (CurrentNetTime <= 0.f)
			{
				CurrentNetTime = NetRate;
				AccelMoveValues(CurrentYaw, CurrentPitch);
				NetCamZoom(FovTarget);
				NetZoomValues(GetFovAlpha(), GetFovZoomValue());
				NetAudioValues(AudioPitchValue, AudioYawValue, AudioZoomValue);
			}
		}
		else
		{
			NetAccelFov.AccelerateTo(NetFovTarget, RemoteAccelerationTime, DeltaTime);
			NetFovYawRot.AccelerateTo(NetYawTarget, RemoteAccelerationTime, DeltaTime);
			NetFovPitchRot.AccelerateTo(NetPitchTarget, RemoteAccelerationTime, DeltaTime);
			NetAccelZoomAlpha.AccelerateTo(NetZoomAlpha, RemoteAccelerationTime, DeltaTime);
			NetAccelZoomValue.AccelerateTo(NetZoomValue, RemoteAccelerationTime, DeltaTime);
			NetAccelAudioRotationPitch.AccelerateTo(NetAudioRotationPitch, RemoteAccelerationTime, DeltaTime);
			NetAccelAudioRotationYaw.AccelerateTo(NetAudioRotationYaw, RemoteAccelerationTime, DeltaTime);
			NetAccelAudioZoom.AccelerateTo(NetAudioZoom, RemoteAccelerationTime, DeltaTime);

			SelfieCamActor.CamFOV = NetAccelFov.Value;
			SelfieCamActor.SetActorRotation(FRotator(0.f, NetFovYawRot.Value, 0.f));
			SelfieCamActor.CameraPivot.SetRelativeRotation(FRotator(NetFovPitchRot.Value, 0.f, 0.f));

			FHazeCameraBlendSettings Blend;
			Blend.BlendTime = 0.5f;
			Player.ApplyFieldOfView(NetAccelFov.Value, Blend, this);
		
			if (PlayerComp.WidgetRef != nullptr)
			{
				PlayerComp.WidgetRef.BP_SetZoomValue(NetAccelZoomAlpha.Value);
				PlayerComp.WidgetRef.BP_SetZoomTextValue(NetAccelZoomValue.Value);
			}

			SelfieCamActor.AudioCameraRotatePitchRTCP(NetAccelAudioRotationPitch.Value);
			SelfieCamActor.AudioCameraRotateYawRTCP(NetAccelAudioRotationYaw.Value);
			SelfieCamActor.AudioZoomRTCP(NetAccelAudioZoom.Value);
		}
	}

	void CameraRotationControl(float DeltaTime)
	{
		float PreviousYaw = AccelYawRot.Value;
		float PreviousPitch = AccelPitchRot.Value;

		CameraYaw(DeltaTime);
		CameraPitch(DeltaTime);

		float YawDiff = PreviousYaw - CurrentYaw;
		YawDiff = FMath::Abs(YawDiff);
		float PitchDiff = PreviousPitch - CurrentPitch;
		PitchDiff = FMath::Abs(PitchDiff);	

		AudioRotationValue = PitchDiff + YawDiff;
		AudioPitchValue = PitchDiff;
		AudioYawValue = YawDiff;

		SelfieCamActor.AudioCameraRotatePitchRTCP(AudioPitchValue);
		SelfieCamActor.AudioCameraRotateYawRTCP(AudioYawValue);

		if (AudioRotationValue > 0.005f && !bIsLooking)
		{
			bIsLooking = true;
			SelfieCamActor.AudioStartCameraRotation();
		}
		else if (AudioRotationValue < 0.005f && bIsLooking)
		{
			bIsLooking = false;
			SelfieCamActor.AudioStopCameraRotation();				
		}
	}

	void CameraZoomControl(float DeltaTime)
	{
		float PreviousZoom = AccelFov.Value;

		CameraZoom(DeltaTime);
		
		AudioZoomValue = PreviousZoom - AccelFov.Value;
		AudioZoomValue = FMath::Abs(AudioZoomValue);

		if (AudioZoomValue > 0.f && !bIsZooming)
		{
			bIsZooming = true;
			SelfieCamActor.AudioStartZoom();
		}
		else if (AudioZoomValue == 0.f && bIsZooming)
		{
			bIsZooming = false;
			SelfieCamActor.AudioStopZoom();				
		}

		SelfieCamActor.AudioZoomRTCP(AudioZoomValue);
	}

	UFUNCTION(NetFunction)
	void AccelMoveValues(float AccelYaw, float AccelPitch)
	{
		NetYawTarget = AccelYaw;
		NetPitchTarget = AccelPitch;
	}

	UFUNCTION(NetFunction)
	void NetCamZoom(float InFovTarget)
	{
		NetFovTarget = InFovTarget;
	}

	UFUNCTION(NetFunction)
	void NetZoomValues(float FovAlpha, float FovZoomValue)
	{
		NetZoomAlpha = FovAlpha;
		NetZoomValue = FovZoomValue;
	}

	UFUNCTION(NetFunction)
	void NetAudioValues(float AudioRotationPitch, float AudioRotationYaw, float AudioZoom)
	{
		NetAudioRotationPitch = AudioRotationPitch;
		NetAudioRotationYaw = AudioRotationYaw;
		NetAudioZoom = AudioZoom;
	}

	void CameraZoom(float DeltaTime)
	{
		if (GetAttributeVector2D(AttributeVectorNames::LeftStickRaw).Y > 0.f && FovTarget > ZoomMinFov)
		{
			if (FovTarget > ZoomMinFov)
				FovTarget -= FovAdd * DeltaTime;
			
			if (FovTarget < ZoomMinFov)
				FovTarget = ZoomMinFov;
		}
		else if (GetAttributeVector2D(AttributeVectorNames::LeftStickRaw).Y < 0.f && FovTarget < ZoomMaxFov)
		{
			if (FovTarget < ZoomMaxFov)
				FovTarget += FovAdd * DeltaTime;
			
			if (FovTarget > ZoomMaxFov)
				FovTarget = ZoomMaxFov;
		}

		AccelFov.AccelerateTo(FovTarget, 0.3f, DeltaTime);
		
		FHazeCameraBlendSettings Blend;
		Blend.BlendTime = 0.5f;

		Player.ApplyFieldOfView(FovTarget, Blend, this);

		SelfieCamActor.CamFOV = AccelFov.Value;
	}

	float GetFovAlpha()
	{
		float CurrentFov = FovTarget - ZoomMinFov;
		float NewMaxFov = ZoomMaxFov - ZoomMinFov;
		return CurrentFov / NewMaxFov;
	}

	float GetFovZoomValue()
	{
		float CurrentFov = FovTarget - ZoomMinFov;
		float NewMaxFov = ZoomMaxFov - ZoomMinFov;
		float PercentageFov = CurrentFov / NewMaxFov;
		float BackwardsFov = 1 - (PercentageFov * 0.9f);

		return BackwardsFov * 10.f;
	}

	void CameraYaw(float DeltaTime)
	{
		if (GetAttributeVector2D(AttributeVectorNames::RightStickRaw).X > 0.f && CurrentYaw < YawMax)
			CurrentYaw += GetAttributeVector2D(AttributeVectorNames::RightStickRaw).X / InputDividerYaw;
		else if (GetAttributeVector2D(AttributeVectorNames::RightStickRaw).X < 0.f && CurrentYaw > YawMin)
			CurrentYaw += GetAttributeVector2D(AttributeVectorNames::RightStickRaw).X / InputDividerYaw;

		AccelYawRot.AccelerateTo(CurrentYaw, 0.5f, DeltaTime);
	}

	void CameraPitch(float DeltaTime)
	{
		if (GetAttributeVector2D(AttributeVectorNames::RightStickRaw).Y > 0.f && CurrentPitch < PitchMax)
			CurrentPitch += GetAttributeVector2D(AttributeVectorNames::RightStickRaw).Y / InputDividerPitch;
		else if (GetAttributeVector2D(AttributeVectorNames::RightStickRaw).Y < 0.f && CurrentPitch > PitchMin)
			CurrentPitch += GetAttributeVector2D(AttributeVectorNames::RightStickRaw).Y / InputDividerPitch;

		AccelPitchRot.AccelerateTo(CurrentPitch, 0.5f, DeltaTime);
	}
}