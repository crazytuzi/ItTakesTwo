import Vino.Movement.Grinding.UserGrindComponent;
import Vino.Movement.Components.MovementComponent;
import Vino.Audio.Movement.PlayerMovementAudioComponent;
import Peanuts.Audio.HazeAudioEffects.DopplerEffect;
import Vino.Audio.PhysMaterials.PhysicalMaterialAudio;
import Vino.Audio.Footsteps.FootstepStatics;
import Peanuts.Audio.AudioStatics;
import Vino.Audio.Capabilities.AudioTags;

enum ECurrentGrindingDirection
{
	// If closed loop
	None,
	TowardsEnd,
	TowardsStart
}

class UCharacterGrindingAudioCapability : UHazeCapability
{
	AHazePlayerCharacter Player;
	UUserGrindComponent UserGrindComp;
	UPlayerHazeAkComponent PlayerHazeAkComp;
	EHazeDopplerObserverType PlayerTarget;
	UHazeMovementComponent MoveComp;
	UPlayerMovementAudioComponent AudioMoveComp;

	default CapabilityTags.Add(AudioTags::Grinding);

	UAkAudioEvent GrindingAudioEvent;
	UPhysicalMaterialAudio AudioPhysMat;
	int32 GrindLoopingEventInstanceId = -1;

	EHazeUpdateSplineStatusType CurrentSplineStatus = EHazeUpdateSplineStatusType::Invalid;
	FHazeSplineSystemPosition LastSplinePos;
	ECurrentGrindingDirection LastDirection;
	private bool bShouldSpatializeDismount = false;
	private bool bInitializedDirection = false;
	private bool bCanInitializeSeek = false;
	private bool bInitializedSeek = false;

	// Grinding passbys disabled until we have fixed predicting spline direction
	/*
	UDopplerEffect GrindingDoppler;
	FDopplerPassbyEvent GrindingPassbyInstance;
	UAkAudioEvent GrindingPassbyEvent;
	float GrindingPassbyEventApexTime;
	float GrindingPassbyActivationDelayTimer;
	*/

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);	
		UserGrindComp = UUserGrindComponent::Get(Owner);
		PlayerHazeAkComp = UPlayerHazeAkComponent::Get(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		AudioMoveComp = UPlayerMovementAudioComponent::Get(Owner);

		// TODO: Passbys for grinding are disabled until we can get players relative velocity with regards to spline direction
		/*
		GrindingDoppler = Cast<UDopplerEffect>(PlayerHazeAkComp.AddEffect(UDopplerEffect::StaticClass()));
		PlayerTarget = Player.IsMay() ? EHazeDopplerObserverType::Cody : EHazeDopplerObserverType::May;
		GrindingDoppler.SetObjectDopplerValues(false, Observer = PlayerTarget, Driver = EHazeDopplerDriverType::Both, bGrindingDoppler = true);
		GrindingDoppler.SetEnabled(false);	
		*/	
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{	
		if (!UserGrindComp.HasActiveGrindSpline())
       		return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!UserGrindComp.HasActiveGrindSpline())
       		return EHazeNetworkDeactivation::DeactivateLocal;

		if (CurrentSplineStatus == EHazeUpdateSplineStatusType::AtEnd)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		if(UserGrindComp.ActiveGrindSpline.AudioPhysmatOverride == nullptr) 
			AudioPhysMat = PhysicalMaterialAudio::GetPhysicalMaterialAudioAsset(UserGrindComp.CurrentSplineMesh, UserGrindComp.ActiveGrindSpline.AudioMaterialIndex);
		else
			AudioPhysMat = UserGrindComp.ActiveGrindSpline.AudioPhysmatOverride;

		
		UAkAudioEvent MountEvent;
		if(AudioPhysMat != nullptr)
		{
			if(Player.IsMay())
			{
				GrindingAudioEvent = AudioPhysMat.MayMaterialEvents.MayMaterialGrindLoopEvent;
				MountEvent = AudioPhysMat.MayMaterialEvents.MayMaterialGrindMountEvent;
				//GrindingPassbyEvent = AudioPhysMat.MayMaterialEvents.MayMaterialGrindPassbyEvent;
				//GrindingPassbyEventApexTime = AudioPhysMat.MayMaterialEvents.MayGrindingPassbyEventApexTime;
			}
			else
			{
				GrindingAudioEvent = AudioPhysMat.CodyMaterialEvents.CodyMaterialGrindLoopEvent;
				MountEvent = AudioPhysMat.CodyMaterialEvents.CodyMaterialGrindMountEvent;
				//GrindingPassbyEvent = AudioPhysMat.CodyMaterialEvents.CodyMaterialGrindPassbyEvent;
				//GrindingPassbyEventApexTime = AudioPhysMat.CodyMaterialEvents.CodyGrindingPassbyEventApexTime;
			}

			AudioMoveComp.GrindingOverrideAudioPhysmat = AudioPhysMat;
		}
		if(GrindingAudioEvent == nullptr)
		{
			GrindingAudioEvent = AudioMoveComp.GrindingEvents.DefaultGrindingLoopEvent;
			//GrindingPassbyEvent = AudioMoveComp.GrindingEvents.DefaultGrindingPassbyEvent;
			//GrindingPassbyEventApexTime	= AudioMoveComp.GrindingEvents.DefaultGrindingPassbyEventApexTime;
		}
		
		GrindLoopingEventInstanceId = PlayerHazeAkComp.HazePostEvent(GrindingAudioEvent).PlayingID;
		Player.PlayerHazeAkComp.HazePostEvent(MountEvent);

		/*
		GrindingDoppler.SetEnabled(true);		
		GrindingPassbyActivationDelayTimer = 0.f;	
		*/

		LastSplinePos = UserGrindComp.FollowComp.GetPosition();
		bShouldSpatializeDismount = UserGrindComp.ActiveGrindSpline.bSpatializeDismount;
		bInitializedDirection = false;
		bInitializedSeek = false;
		bCanInitializeSeek = false;

		if(UserGrindComp.ActiveGrindSpline.bSeekOnLength && !UserGrindComp.ActiveGrindSpline.Spline.IsClosedLoop())
		{
			FHazeSplineSystemPosition SplinePos = UserGrindComp.FollowComp.GetPosition();
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{	
		float ScaledGrindingSpeed = HazeAudio::NormalizeRTPC01(UserGrindComp.CurrentSpeed, 1000.f, 2300.f);
		PlayerHazeAkComp.SetRTPCValue(HazeAudio::RTPC::GrindingSpeed, ScaledGrindingSpeed);
		ECurrentGrindingDirection CurrentDirection = ECurrentGrindingDirection::None;

		// TODO: Passbys for grinding are disabled until we can get players relative velocity with regards to spline direction
		/*
		if(GrindingPassbyActivationDelayTimer < 1.f)
			GrindingPassbyActivationDelayTimer += DeltaTime;
		else if(GrindingDoppler.PassbyEvents.Num() == 0)		
			GrindingDoppler.PlayPassbySound(GrindingPassbyEvent, GrindingPassbyEventApexTime, 1.5f, VelocityAngle = 0.8f, MinRelativeSpeed = 15.f);		
		*/		

		// Set rtpc for progression along spline if not a closed loop. Currently checking against only current spline segment
		if(!UserGrindComp.ActiveGrindSpline.Spline.IsClosedLoop())
		{
			FHazeSplineSystemPosition SplinePos = UserGrindComp.FollowComp.GetPosition();
			float DistAlongSplineRtpcValue = SplinePos.DistanceAlongSpline / UserGrindComp.ActiveGrindSpline.Spline.SplineLength;
			if(!IsMovingTowardsEnd(SplinePos, CurrentDirection) && CurrentDirection != ECurrentGrindingDirection::None)
			{
				if(UserGrindComp.ActiveGrindSpline.bAudioSplineLengthRtpcAbsolute)
					DistAlongSplineRtpcValue = 1 - DistAlongSplineRtpcValue;				
			}

			if(!bInitializedDirection)
			{
				if(CurrentDirection != ECurrentGrindingDirection::None)
				{
					float DirectionValue = CurrentDirection == ECurrentGrindingDirection::TowardsEnd ? 1 : -1;

					// If level designers have inconsintent start/end for the same mesh, we might need to invert our calculations
					if(UserGrindComp.ActiveGrindSpline.bAudioSplineDirectionRtpcInvert)
						DirectionValue = DirectionValue * -1.f;

					PlayerHazeAkComp.SetRTPCValue("Rtpc_Grinding_Spline_Direction", DirectionValue);
					LastDirection = CurrentDirection;
					bInitializedDirection = true;
					bCanInitializeSeek = true;
				}
			}
			if(!bInitializedSeek && bCanInitializeSeek && UserGrindComp.ActiveGrindSpline.bSeekOnLength)
			{
				const float SeekLength = GetSplineSeekValue(SplinePos, CurrentDirection);
				PlayerHazeAkComp.SeekOnPlayingEvent(GrindingAudioEvent, GrindLoopingEventInstanceId, SeekLength - UserGrindComp.ActiveGrindSpline.SeekSlewValue);
				bInitializedSeek = true;
			}

			if(UserGrindComp.ActiveGrindSpline.bAudioSetSplineLengthRTPC)
				PlayerHazeAkComp.SetRTPCValue(HazeAudio::RTPC::GrindingSplineLengthPosition, DistAlongSplineRtpcValue);

			LastSplinePos = SplinePos;

			if(DidDirectionChange(CurrentDirection))
			{
				PlayerHazeAkComp.SetRTPCValue("Rtpc_Grinding_Spline_Direction", 0.f, 0);

				if(UserGrindComp.ActiveGrindSpline.bSeekOnLength && AudioPhysMat != nullptr)
				{
					const float SeekPositionValue = GetSplineSeekValue(SplinePos, CurrentDirection);
					PlayerHazeAkComp.SeekOnPlayingEvent(GrindingAudioEvent, GrindLoopingEventInstanceId, SeekPositionValue - UserGrindComp.ActiveGrindSpline.SeekSlewValue);
				}

				// If level designers have inconsintent start/end for the same mesh, we might need to invert our calculations
				float DirectionValue = CurrentDirection == ECurrentGrindingDirection::TowardsEnd ? 1 : -1;
				if(UserGrindComp.ActiveGrindSpline.bAudioSplineDirectionRtpcInvert)
						DirectionValue = DirectionValue * -1.f;

				PlayerHazeAkComp.SetRTPCValue("Rtpc_Grinding_Spline_Direction", DirectionValue, UserGrindComp.ActiveGrindSpline.InterpolateDirectionRtpc);

				if(UserGrindComp.ActiveGrindSpline.bRetriggerOnDirectionChange && AudioPhysMat != nullptr)				
				{					
					PlayerHazeAkComp.HazeStopEvent(GrindLoopingEventInstanceId, 100.f);
					UAkAudioEvent RetriggerEvent;
					if(Player.IsMay())
						RetriggerEvent = AudioPhysMat.MayMaterialEvents.MayMaterialGrindRetriggerEvent;
					else
						RetriggerEvent = AudioPhysMat.CodyMaterialEvents.CodyMaterialGrindRetriggerEvent;					

					GrindLoopingEventInstanceId = PlayerHazeAkComp.HazePostEvent(RetriggerEvent).PlayingID;
				}
			}

			LastDirection = CurrentDirection;
		}
	}

	bool IsMovingTowardsEnd(const FHazeSplineSystemPosition& CurrentSplinePos,  ECurrentGrindingDirection& OutGrindingDirection)
	{
		if(UserGrindComp.ActiveGrindSpline.Spline.IsClosedLoop())
			return false;

		const float DistAlongSpline = CurrentSplinePos.DistanceAlongSpline / UserGrindComp.ActiveGrindSpline.Spline.SplineLength;
		const float LastDistAlongSpline = LastSplinePos.DistanceAlongSpline / UserGrindComp.ActiveGrindSpline.Spline.SplineLength;

		if(DistAlongSpline > LastDistAlongSpline)
			OutGrindingDirection = ECurrentGrindingDirection::TowardsEnd;
		else if(DistAlongSpline < LastDistAlongSpline)
			OutGrindingDirection = ECurrentGrindingDirection::TowardsStart;
		else
			OutGrindingDirection = ECurrentGrindingDirection::None;

		return DistAlongSpline > LastDistAlongSpline;
	}

	bool DidDirectionChange(const ECurrentGrindingDirection& CurrentDirection)
	{
		if(CurrentDirection != ECurrentGrindingDirection::None && CurrentDirection != LastDirection)
			return true;

		return false;
	}

	float GetSplineSeekValue(const FHazeSplineSystemPosition& CurrentSplinePos, ECurrentGrindingDirection& CurrentDirection)
	{
		float SeekPositionValue = CurrentSplinePos.DistanceAlongSpline / UserGrindComp.ActiveGrindSpline.Spline.SplineLength;
		if(CurrentDirection == ECurrentGrindingDirection::TowardsStart)
			SeekPositionValue = 1 - SeekPositionValue;

		return SeekPositionValue;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		UAkAudioEvent GrindingStopAudioEvent;

		if(AudioPhysMat != nullptr)
			GrindingStopAudioEvent = Player.IsMay() ? AudioPhysMat.MayMaterialEvents.MayMaterialGrindStopEvent : AudioPhysMat.CodyMaterialEvents.CodyMaterialGrindStopEvent;			
		else
			GrindingStopAudioEvent = AudioMoveComp.GrindingEvents.DefaultGrindingDismountEvent;

		if(GrindingStopAudioEvent != nullptr)
		{
			PlayerHazeAkComp.HazePostEvent(GrindingStopAudioEvent);
			if(bShouldSpatializeDismount)
			{
				UAkAudioEvent DismountEvent = Player.IsMay() ? AudioPhysMat.MayMaterialEvents.MayMaterialGrindDismountEvent : AudioPhysMat.CodyMaterialEvents.CodyMaterialGrindDismountEvent;
				UHazeAkComponent::HazePostEventFireForget(DismountEvent, LastSplinePos.GetWorldTransform());
			}			
		}
		else
			PlayerHazeAkComp.HazeStopEvent(GrindLoopingEventInstanceId);

		AudioMoveComp.GrindingOverrideAudioPhysmat = nullptr;
		GrindingAudioEvent = nullptr;
		bShouldSpatializeDismount = false;
		LastDirection = ECurrentGrindingDirection::None;
		PlayerHazeAkComp.SetRTPCValue("Rtpc_Grinding_Spline_Direction", 0.f);

		/*
		GrindingDoppler.SetEnabled(false);		
		GrindingDoppler.StopPassbySound(GrindingPassbyEvent);	
		PlayerHazeAkComp.SetRTPCValue(HazeAudio::RTPC::GrindingSpeed, 0.f, 200);	
		GrindingPassbyActivationDelayTimer = 0.0f;	
		*/
	}	

}