import Vino.Movement.Components.MovementComponent;
import Vino.Audio.Movement.PlayerMovementAudioComponent;
import Vino.Movement.Grinding.UserGrindComponent;
import Vino.Movement.MovementSystemTags;
import Vino.Movement.Capabilities.Swimming.Core.SwimmingTags;
import Vino.Pickups.Capabilities.PickupCapability;
import Peanuts.Audio.AudioStatics;
import Cake.LevelSpecific.SnowGlobe.Magnetic.MagneticTags;
import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingTags;
import Vino.Audio.Capabilities.AudioTags;

class UPlayerVelocityDataUpdateCapability : UHazeCapability
{
	default CapabilityDebugCategory = n"Audio";
	default CapabilityTags.Add(AudioTags::PlayerAudioVelocityData);
	
	default TickGroup = ECapabilityTickGroups::AfterGamePlay;
	default TickGroupOrder = 100;

	float LastNormalizedAngularVelocity;
	float LastNormalizedVelocityDelta;
	float LastNormalizedSpeed;
	float LastNormalizedSlopeTilt;
	float LastNormalizedCombinedVelocity;
	
	HazeAudio::EPlayerMovementState LastTraversalTypeRtpc;
	HazeAudio::EPlayerMovementState LastTraversalTypeSwitch;

	UHazeMovementComponent MoveComp;
	AHazePlayerCharacter Player;
	UPlayerHazeAkComponent HazeAkComp;
	UPlayerMovementAudioComponent AudioMoveComp;
	UUserGrindComponent UserGrindComp;	

	bool bHasUpdatedAirborne = true;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		HazeAkComp = UPlayerHazeAkComponent::Get(Owner, n"PlayerHazeAkComponent");		
		AudioMoveComp = UPlayerMovementAudioComponent::Get(Owner);
		UserGrindComp = UUserGrindComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(MoveComp.IsDisabled())
			return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(MoveComp.IsDisabled())
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector Velocity = MoveComp.Velocity;
		if (MoveComp.CanCalculateMovement())
			Velocity = MoveComp.ActualVelocity;
		
		float VelocitySize = Velocity.Size();
		float PlayerNormalizedSpeed = FMath::Lerp(0.f, Math::GetPercentageBetween(0.f, 1200.f, VelocitySize), 1.5f);		

		float VelocityDelta = MoveComp.VelocityDelta;

		float AngularRadianDelta = MoveComp.RotationDelta;
		float AngularVelocity = AngularRadianDelta / DeltaTime;

		bool bIsAirborne = MoveComp.IsAirborne();
		// // Override IsAirbourne in cutscenes, MoveComp is normally incorrect...
		// if (Player.bIsControlledByCutscene && MoveComp.CanCalculateMovement() && MoveComp.IsAirborne())
		// {
		// 	// From AnimNotify_Footstep
		// 	FVector HipLoc = Player.Mesh.GetSocketLocation(n"Hips");
		// 	float TraceDistance = Player.Mesh.BoundingBoxExtents.Z * 2.f;
		// 	FHazeHitResult Hit;
		// 	bIsAirborne = !HazeAudio::PerformGroundTrace(HipLoc, HipLoc + Player.MovementWorldUp * -TraceDistance, Hit);
		// }

		float SlopeTilt = 0.f;
		if (!bIsAirborne && !MoveComp.Velocity.IsNearlyZero())
		{
			FVector VelocityPlaneForward = MoveComp.Velocity.ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal();
			SlopeTilt = Math::DotToDegrees(MoveComp.Velocity.GetSafeNormal().DotProduct(VelocityPlaneForward));
			SlopeTilt = SlopeTilt * FMath::Sign(MoveComp.Velocity.DotProduct(MoveComp.WorldUp));
		}

		float NormalizedVelocityDelta = FMath::Abs(FMath::Lerp(0.f, Math::GetPercentageBetween(0.f, 60.f, VelocityDelta), 1.f));
		float NormalizedAngularVelocity = FMath::Lerp(0.f, 1.f, Math::GetPercentageBetween(0.f, 25.f, AngularVelocity));		
		float NormalizedSlopeTilt = FMath::Lerp(-1.f, Math::GetPercentageBetween(0.f, 45.f, SlopeTilt), 1.f);
		float NormalizedCombinedVelocity = FMath::Max(PlayerNormalizedSpeed, NormalizedAngularVelocity);

		if(FMath::IsNearlyZero(MoveComp.VerticalVelocity, 5.f))
			HazeAkComp.SetRTPCValue("Rtpc_Player_InAir_Direction", 0.f);
		else
			HazeAkComp.SetRTPCValue("Rtpc_Player_InAir_Direction", FMath::Sign(MoveComp.VerticalVelocity));

		if(bIsAirborne && 
			bHasUpdatedAirborne &&
			!Player.bIsControlledByCutscene &&
			!Player.IsAnyCapabilityActive(AudioTags::FallingAudioBlocker))
		{
			HazeAkComp.SetRTPCValue(HazeAudio::RTPC::CharacterIsAirborne, 1, 100.f);
			HazeAkComp.SetRTPCValue(HazeAudio::RTPC::VOEffortsIsInAir, 1, 0.f);
			bHasUpdatedAirborne = false;
			HazeAkComp.HazePostEvent(AudioMoveComp.FallingSkydivingEvents.StartFallingEvent);
			//PrintScaled("INAIR", 1.f , FLinearColor::DPink ,3.f);
		}
		else if (!bIsAirborne && !bHasUpdatedAirborne)
		{
			HazeAkComp.SetRTPCValue(HazeAudio::RTPC::CharacterIsAirborne, 0, 0);
			HazeAkComp.SetRTPCValue(HazeAudio::RTPC::VOEffortsIsInAir, 0, 0.f);			
			bHasUpdatedAirborne = true;
			HazeAkComp.HazePostEvent(AudioMoveComp.FallingSkydivingEvents.StopFallingEvent);
			//PrintScaled("GROUND", 1.f , FLinearColor::DPink ,3.f);
		}

		UHazeCameraComponent PlayerCamera = Player.GetCurrentlyUsedCamera();

		FVector CharacterPos = Player.GetActorLocation();

		if (PlayerCamera != nullptr)
		{
			FVector CameraPos = PlayerCamera.GetWorldLocation();
			float PlayerCameraDistance = CharacterPos.Distance(CameraPos);
			float NormalizedCameraDistance = FMath::Lerp(0.f, Math::GetPercentageBetween(35.f, 1400.f, PlayerCameraDistance), 1.f);
		}

		if (IsDebugActive())
		{
			Print("NormalizedSpeed: " + PlayerNormalizedSpeed, 0.f);
			Print("VelocityDelta: " + NormalizedVelocityDelta, 0.f);
			Print("AngularVelocity: " + NormalizedAngularVelocity, 0.f);
			Print("SlopeTilt:" + NormalizedSlopeTilt, 0.f);	
			Print("Is Airborne: " + bIsAirborne, 0.f);
			Print("Is Crouching: " + (Player.IsAnyCapabilityActive(MovementSystemTags::Crouch) || Player.IsAnyCapabilityActive(MovementSystemTags::DoublePull)), 0.f);	
			Print("Is Sprinting: " + Player.IsAnyCapabilityActive(MovementSystemTags::Sprint), 0.f);
		}

		//Sending values to Wwise as UMovieSceneAkAudioRTPCSection		
		if(PlayerNormalizedSpeed != LastNormalizedSpeed)
		{
			HazeAkComp.SetRTPCValue("Rtpc_Player_Velocity" , FMath::Clamp(PlayerNormalizedSpeed, 0.f, 10.f), 0);
			LastNormalizedSpeed = PlayerNormalizedSpeed;

			// PlayerMovementAudioCapability has flagged us as going from standing still to movement, seek to update body loop playback position
			if(ConsumeAction(n"AudioStartedDash") == EActionStateStatus::Active)
				HazeAkComp.SeekOnPlayingEvent(AudioMoveComp.BodyMovementEvent, AudioMoveComp.BodyMovementEventInstance.PlayingID, 1.f, true, true, true);

			else if(PlayerNormalizedSpeed > 0.1f && AudioMoveComp.bSeekOnBodyMovement)
			{
				HazeAkComp.SeekOnPlayingEvent(AudioMoveComp.BodyMovementEvent, AudioMoveComp.BodyMovementEventInstance.PlayingID, 1.f, true, true, true);
				AudioMoveComp.bSeekOnBodyMovement = false;
			}			
		}

		if(NormalizedAngularVelocity != LastNormalizedAngularVelocity)
		{
			HazeAkComp.SetRTPCValue(HazeAudio::RTPC::CharacterAngularVelocity, FMath::Clamp(NormalizedAngularVelocity, 0.f, 1.f));
			LastNormalizedAngularVelocity = NormalizedAngularVelocity;

			HazeAkComp.SetRTPCValue("Rtpc_Player_InAir_Angular_Velocity", HazeAudio::NormalizeRTPC(NormalizedAngularVelocity, 0.f, 0.2f, 0.f, 1.f));
		}

		if(NormalizedVelocityDelta != LastNormalizedVelocityDelta)
		{
			HazeAkComp.SetRTPCValue(HazeAudio::RTPC::CharacterVelocityDelta, FMath::Clamp(NormalizedVelocityDelta, 0.f, 1.f));
			LastNormalizedVelocityDelta = NormalizedVelocityDelta;
		}

		if(NormalizedSlopeTilt != LastNormalizedSlopeTilt)
		{
			LastNormalizedSlopeTilt = FMath::FInterpConstantTo(LastNormalizedSlopeTilt, NormalizedSlopeTilt, DeltaTime, 0.05f);
			HazeAkComp.SetRTPCValue(HazeAudio::RTPC::CharacterSlopeTilt, FMath::Clamp(LastNormalizedSlopeTilt, -1.f, 1.f));
		}

		if (NormalizedCombinedVelocity != LastNormalizedCombinedVelocity)
		{
			HazeAkComp.SetRTPCValue("Rtpc_Player_Velocity_AngularVelocity_Combined", FMath::Clamp(NormalizedCombinedVelocity, 0, 1));
			LastNormalizedCombinedVelocity = NormalizedCombinedVelocity;
		}

		if(CanUpdateTraversalType())
		{
			HazeAudio::EPlayerMovementState MovementType = HazeAudio::EPlayerMovementState::Idle;
			SetTraversalType(bIsAirborne, PlayerNormalizedSpeed, MovementType);

			if(LastTraversalTypeRtpc != MovementType)
			{
				HazeAkComp.SetRTPCValue(HazeAudio::RTPC::CharacterMovementType, MovementType, 0.f);
				LastTraversalTypeRtpc = MovementType;			
			}

			if(LastTraversalTypeSwitch != MovementType)
			{
				AudioMoveComp.SetTraversalTypeSwitch(MovementType);
				LastTraversalTypeSwitch = MovementType;
			}

			if(MovementType == HazeAudio::EPlayerMovementState::Skydive)
			{
				AudioMoveComp.PerformSkydiveTrace();
			}
		}
	}

	void SetTraversalType(bool bIsAirborne, const float& PlayerNormalizedSpeed, HazeAudio::EPlayerMovementState& OutMovementType)
	{
		if(PlayerNormalizedSpeed <= 0 && !bIsAirborne)
			OutMovementType = HazeAudio::EPlayerMovementState::Idle;	

		// Super ugly way of getting players current type of traversal
		else if(Player.IsAnyCapabilityActive(MovementSystemTags::SlopeSlide))
		{
			OutMovementType = HazeAudio::EPlayerMovementState::Slide;
		}		
		else if((Player.IsAnyCapabilityActive(MovementSystemTags::Crouch) && !bIsAirborne) 
				|| Player.IsAnyCapabilityActive(MovementSystemTags::DoublePull))
		{
			OutMovementType = HazeAudio::EPlayerMovementState::Crouch;
		}
		else if(Player.IsAnyCapabilityActive(MovementSystemTags::Sprint) || (Player.IsAnyCapabilityActive(MovementSystemTags::Dash)) && !bIsAirborne)
		{
			OutMovementType = HazeAudio::EPlayerMovementState::Sprint;
		}
		else if(Player.IsAnyCapabilityActive(MovementSystemTags::Falling) || Player.IsAnyCapabilityActive(SwimmingTags::Breach))
		{
			OutMovementType = HazeAudio::EPlayerMovementState::Falling;
		}
		else if(Player.IsAnyCapabilityActive(MovementSystemTags::SkyDive))
		{
			OutMovementType = HazeAudio::EPlayerMovementState::Skydive;
		}
		else if(Player.IsAnyCapabilityActive(MovementSystemTags::Grinding) && UserGrindComp.HasActiveGrindSpline())
		{
 			OutMovementType = HazeAudio::EPlayerMovementState::Grind;
		}
		else if(Player.IsAnyCapabilityActive(PickupTags::PickupAudioCapability) || Player.IsAnyCapabilityActive(FMagneticTags::MagneticPlayerAttractionPerchMovementCapability))
		{
			OutMovementType = HazeAudio::EPlayerMovementState::HeavyWalk;
		}
		else if(Player.IsAnyCapabilityActive(SwimmingTags::Underwater) || Player.IsAnyCapabilityActive(SwimmingTags::Surface))
		{
			OutMovementType = HazeAudio::EPlayerMovementState::Swimming;
		}
		else if(Player.IsAnyCapabilityActive(n"SwingGrapple"))
		{
			OutMovementType = HazeAudio::EPlayerMovementState::Swing;
		}
		else if(Player.IsAnyCapabilityActive(IceSkatingTags::IceSkating) && !Player.IsAnyCapabilityActive(AudioTags::Grinding))
		{
			OutMovementType = HazeAudio::EPlayerMovementState::IceSkating;
		}
		else if (!bIsAirborne)
		{	
			OutMovementType = HazeAudio::EPlayerMovementState::Run;
		}
		else
		{
	 		OutMovementType = HazeAudio::EPlayerMovementState::Idle;
		}
	}

	bool CanUpdateTraversalType()
	{
		return !Player.IsAnyCapabilityActive(n"AudioTraversalTypeOverride");
	}
	
	UFUNCTION(BlueprintOverride)
	FString GetDebugString()
	{
		if(IsActive())
		{
			FString DebugText = "";
			if(HasControl())
			{
				DebugText += "Control Side\n";
			}
			else
			{
				DebugText += "Slave Side\n";
			}
			return DebugText;
		}

		return "Not Active";
	}
}
