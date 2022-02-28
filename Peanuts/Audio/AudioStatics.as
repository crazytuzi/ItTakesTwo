import float GetPanningMultiplierValue() from "Peanuts.Audio.HazeAudioManager.AudioManagerStatics";

struct FPlayerHealthAudioParams
{
	FString FilteringRTPC = "";
	FName CombinedHealthFilteringAttribute = n"AudioSetHealthFilteringValue";
	const float FILTER_HOLD = 1.f;
	const float FilterAttackSlew = 500.f;
	const float FilterReleaseSlew = 2000.f;
}

namespace HazeAudio
{
	FVector GetEarsLocation(AHazePlayerCharacter Player)
	{
		FVector EarsLocation = Player.Mesh.GetSocketLocation(n"Head");

		return EarsLocation;
	}

	FTransform GetEarsTransform(AHazePlayerCharacter Player)
	{
		return Player.Mesh.GetSocketTransform(n"Head");
	}

	FTransform GetListenerTransform(AHazePlayerCharacter Player, const FVector& ViewLocation, const FRotator& ViewRotation, float ViewRatio)
	{
		FVector EarsLocation = GetEarsLocation(Player);

		FVector ListenerLocation = FMath::Lerp(EarsLocation, ViewLocation, ViewRatio);			
		FTransform ListenerTransform = FTransform(ListenerLocation);
		ListenerTransform.SetRotation(ViewRotation);
		return ListenerTransform;		
	}

	UHazeListenerComponent GetListenerComponent(AHazePlayerCharacter Player)
	{
		return Player.ListenerComponent;
	}

	bool GetPlayerScreenPosition(AHazePlayerCharacter Player, AActor ActorOverride, FVector2D& RelativeScreenPosition)
	{
		FVector WorldPosition = ActorOverride != nullptr ? ActorOverride.GetActorLocation() : Player.GetActorLocation();
		return SceneView::ProjectWorldToViewpointRelativePosition(Player, WorldPosition, RelativeScreenPosition);
	}

	void UpdateListenerTransform(AHazePlayerCharacter Player, float ViewRatio)
	{
		UHazeListenerComponent ListenerComp = GetListenerComponent(Player);
		if (ListenerComp == nullptr)
			return;

		UHazeCameraComponent Camera = Player.GetCurrentlyUsedCamera();
		if (Camera == nullptr)
			return;
		
		FVector CameraLocation = Player.GetPlayerViewLocation();
		FRotator CameraRotation = Player.GetPlayerViewRotation();	

		FTransform ListenerTransform = GetListenerTransform(Player, CameraLocation, CameraRotation, ViewRatio);
		ListenerComp.SetWorldTransform(ListenerTransform);		
	}

	// Override the position from the players camera with ActorOverride
	void UpdateListenerTransform(AHazePlayerCharacter Player, FVector PositionOverride, float ViewRatio)
	{
		UHazeListenerComponent ListenerComp = GetListenerComponent(Player);
		if (ListenerComp == nullptr)
			return;

		UHazeCameraComponent Camera = Player.GetCurrentlyUsedCamera();
		if (Camera == nullptr)
			return;
		
		FRotator CameraRotation = Player.GetPlayerViewRotation();	
		FTransform ListenerTransform = GetListenerTransform(Player, PositionOverride, CameraRotation, ViewRatio);
		ListenerComp.SetWorldTransform(ListenerTransform);		
	}

	void DebugListenerLocations(AHazePlayerCharacter Player, UObject ObjectOverride = nullptr, FVector OverridePosition = FVector())
	{
		UHazeCameraComponent Camera = Player.GetCurrentlyUsedCamera();
		FVector CameraLocation = ObjectOverride != nullptr ? OverridePosition : Camera.GetViewLocation();
		FRotator CameraRotation = Camera.GetViewRotation();
		
		UHazeListenerComponent ListenerComp = GetListenerComponent(Player);
		FVector ListenerLocation = ListenerComp.GetWorldLocation();
		FRotator ListenerRotation = ListenerComp.GetWorldRotation();

		System::DrawDebugLine(ListenerLocation, ListenerLocation + (ListenerComp.ForwardVector * 500), LineColor = FLinearColor::Blue);
		

		Debug::DrawForegroundDebugPoint(GetEarsLocation(Player), 10.f, FLinearColor(1.f, 0.f, 0.f));
		Debug::DrawForegroundDebugPoint(CameraLocation, 10.f, FLinearColor::Blue);
		Debug::DrawForegroundDebugPoint(ListenerLocation, 10.f, FLinearColor::Purple);
	}

	void SetGlobalRTPC(FString Parameter, float Value, float InterpolationTime = 0.f)
	{
		AkGameplay::SetRTPCValue(Value, InterpolationTime, nullptr, FName(Parameter));
	}

	UFUNCTION(BlueprintCallable)
	void SetPlayerPanning(UHazeAkComponent HazeAkComp, AHazeActor Actor, float RtpcValueOverride = -2.f)
	{
		if(HazeAkComp == nullptr || !HazeAkComp.bIsEnabled || !HazeAkComp.IsGameObjectRegisteredWithWwise())
			return;

		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Actor);
		if(Player == nullptr)
		{
			AHazePlayerCharacter AttachedPlayer = nullptr;
			TArray<AActor> OutActors;

			if(Actor != nullptr)
			{
				Actor.GetAttachedActors(OutActors);
				for(AActor AttachActor : OutActors)
				{
					AttachedPlayer = Cast<AHazePlayerCharacter>(AttachActor);
					if(AttachedPlayer != nullptr)
					{
						Player = AttachedPlayer;
						break;
					}
				}
			}				
		}

		if(Player == nullptr && RtpcValueOverride == -2.f)
			return;

		float SpeakerPanningValue;

		if(RtpcValueOverride != -2.f)
			SpeakerPanningValue = RtpcValueOverride;
		
		else if(Player.IsMay())
		{
			SpeakerPanningValue = -1.f;
		}
		else
		{
			SpeakerPanningValue = 1.f;
		}

		HazeAkComp.SetRTPCValue(HazeAudio::RTPC::CharacterSpeakerPanningLR, SpeakerPanningValue * GetPanningMultiplierValue(), 0.f);
	}

	float GetPlayerCameraDistanceRTPCValue(AHazePlayerCharacter& Player)
	{	
		UHazeCameraComponent PlayerCam = Player.CurrentlyUsedCamera;
		if(PlayerCam == nullptr)
			return 0.3f;

		const float Dist = PlayerCam.GetWorldLocation().Distance(Player.GetActorCenterLocation());
		const float NormalizedDistance = NormalizeRTPC01(Dist, 70.f, 3000.f);

		// Currently the RTPC has a long range to allow picking up on situations where the camera is zoomed out and far away from the players. 
		// In normal gameplay the RTPC will max out at around 0.5 (0.3 is around the "normal" position)

		return NormalizedDistance;
	}

	bool PerformGroundTrace(FVector Start, FVector End, FHazeHitResult& Hit)
	{
		FHazeTraceParams FloorTrace;
		FloorTrace.InitWithCollisionProfile(n"PlayerCharacter");
		FloorTrace.From = Start;
		FloorTrace.To = End;

		return FloorTrace.Trace(Hit);
	}

	FPlayerHealthAudioParams GetHealthAudioParams(AHazePlayerCharacter& Player)
	{
		FPlayerHealthAudioParams AudioParams;

		if(Player.IsMay())
		{
			AudioParams.FilteringRTPC = "Rtpc_UI_Health_ReSpawnProg_Death_Filtering_Combined_May";
		}
		else
		{		
			AudioParams.FilteringRTPC = "Rtpc_UI_Health_ReSpawnProg_Death_Filtering_Combined_Cody";
		}

		return AudioParams;
	}
	

	////////////////////////////////////////////////////////////////////////////////////////////////////////
	//									ENUMS															  //	
	////////////////////////////////////////////////////////////////////////////////////////////////////////

	enum EHazeMultiplePositionsTrackingType
    {
        BothPlayers,
        May,
        Cody
    };

	enum EHazeAkEventCallBack
	{
		None = 0,
		EndOfEvent = 1,
		Marker = 4,
	};

	enum EPlayerFootstepType
	{
		Run,
		Crouch,
 		Sprint,
		ScuffLowIntensity, 
        ScuffHighIntensity,        
        FootSlide,		
		HandsImpactLowIntensity ,
		HandsImpactHighIntensity,
        HandScuff,
		HandSlide,            			
		LandingLowIntensity,
		LandingHighIntensity,
		AssSlide,
		FootSlideStop,
		HandSlideStop,
		AssSlideStop,
		FootSlideLoop,
		AssSlideLoop,
		ArmFast,
		ArmSlow,
		BodyHighInt,
		BodyLowInt,
		Jump
	};

	enum EMaterialFootstepType
	{
		Soft,
		Hard,		
	};

	enum EMaterialSlideType
	{
		None,
		Smooth,
		Rough
	};

	enum EPlayerMovementState
	{
		Idle,
		Crouch,
		Run,
		Sprint,
		HeavyWalk,
		Slide,
		Grind,
		Falling,
		Skydive,
		Swimming,
		Swing,
		IceSkating
	};

	UFUNCTION(BlueprintCallable)
	int32 GetSpeakerTypeFromEnum(EHazeAudioSpeakerType SpeakerType)
	{
		switch (SpeakerType)
		{
			case(EHazeAudioSpeakerType::Speakers):
				return 0;
			case(EHazeAudioSpeakerType::TV):
				return 1;
			case(EHazeAudioSpeakerType::Headphones):
				return 2;
			default:
				return 0;
		}

		return 0;
	}
	UFUNCTION(BlueprintCallable)
	int32 GetChannelConfigurationFromEnum(EHazeAudioChannelSetup ChannelConfig)
	{
		switch (ChannelConfig)
		{
			case(EHazeAudioChannelSetup::Stereo):
				return 0;
			case(EHazeAudioChannelSetup::Surround):
				return 1;
			default:
				return 0;
		}

		return 0;
	}

	UFUNCTION(BlueprintCallable)
	int32 GetDynamicRangeFromEnum(EHazeAudioDynamicRange DynamicRange)
	{
		switch (DynamicRange)
		{
			case(EHazeAudioDynamicRange::High):
				return 0;
			case(EHazeAudioDynamicRange::Medium):
				return 1;
			case(EHazeAudioDynamicRange::Low):
				return 2;
			default:
				return 0;
		}	

		return 0;
	}

	////////////////////////////////////////////////////////////////////////////////////////////////////////
	//									POSTING EVENTS													  //	
	////////////////////////////////////////////////////////////////////////////////////////////////////////

	void PostEventAtLocation(UAkAudioEvent Event, AActor Actor, FString EventName = "")
	{
		AkGameplay::PostEventAtLocation(Event, Actor.GetActorLocation(), Actor.GetActorRotation(), EventName);
	}

	UHazeAkComponent SpawnAkCompAtLocation(UAkAudioEvent Event, AActor Actor, int Callbackmask = 0, bool bAutoPost = false, FString EventName = "", bool bAutoDestroy = true, int CallBackMask = 0, FOnAkPostEventCallback PostEventCallback = FOnAkPostEventCallback())
	{	
		UAkComponent AkComp = AkGameplay::SpawnAkComponentAtLocation(Event, Actor.GetActorLocation(), Actor.GetActorRotation(), bAutoPost, EventName, bAutoDestroy);					
		return Cast<UHazeAkComponent>(AkComp);
	}

	////////////////////////////////////////////////////////////////////////////////////////////////////////
	//									EVENTS & LOGIC													  //	
	////////////////////////////////////////////////////////////////////////////////////////////////////////

	namespace DEFAULTEVENTS
	{
		const FString PlayMovementMayBodyDefaultEvent = "Play_Characters_Movement_May_Body_Default";
		const FString StopMovementMayBodyDefaultEvent = "Stop_Characters_Movement_May_Body_Default";
		const FString PlayMovementCodyBodyDefaultEvent = "Play_Characters_Movement_Cody_Body_Default";
		const FString StopMovementCodyBodyDefaultEvent = "Stop_Characters_Movement_May_Body_Default";
	}


	namespace RTPC
	{
		// Globals

		const FHazeAkRTPC SoundDistanceToListener = FHazeAkRTPC("Rtpc_Distance");
		const FHazeAkRTPC CharacterCameraDistance = FHazeAkRTPC("Rtpc_Distance_CameraToPlayer");
		const FHazeAkRTPC SoundDistanceToPlayer = FHazeAkRTPC("Rtpc_Distance_SoundToPlayer");
		const FHazeAkRTPC SoundDistanceToPlayerDoppler = FHazeAkRTPC("Rtpc_Distance_SoundToPlayer_Doppler");
		const FHazeAkRTPC ListenerProximityBoostCompensation = FHazeAkRTPC("Rtpc_Distance_Listener_Proximity_Compensation");
		const FHazeAkRTPC ModifiedTimeDilationOverride = FHazeAkRTPC("Rtpc_Object_Modified_Time_Dilation_Override");

		//Music

		const FHazeAkRTPC MusicClassicSongOfLifeMayVocalOn = FHazeAkRTPC("Rtpc_May_VocalOn");
		const FString DebugMusicToggleVolume = "Rtpc_Debug_ToggleMusic_Volume";
		const FString DebugVOToggleVolume = "Rtpc_Debug_ToggleVO_Volume";
		const FString DebugSFXToggleVolume = "Rtpc_Debug_ToggleSFX_Volume";

		const FHazeAkRTPC AmbZoneFade = FHazeAkRTPC("RTPC_AmbientZone_Fade");
		const FHazeAkRTPC AmbZonePanning = FHazeAkRTPC("Rtpc_AmbientZone_Panning");
		// PlayerCharacters

		const FHazeAkRTPC CharacterHealth = FHazeAkRTPC("Rtpc_Character_Health");
		const FHazeAkRTPC CharacterSpeakerPanningLR = FHazeAkRTPC("Rtpc_Speaker_Panning_LR");
		const FHazeAkRTPC CharacterSpeakerPanningFR = FHazeAkRTPC("Rtpc_Speaker_Panning_FR");

		// Player Movement

		const FHazeAkRTPC CharacterVelocityDelta = FHazeAkRTPC("Rtpc_Velocity_Delta");
		const FHazeAkRTPC CharacterAngularVelocity = FHazeAkRTPC("Rtpc_Angular_Velocity");
		const FHazeAkRTPC CharacterSlopeTilt = FHazeAkRTPC("Rtpc_Slope_Tilt");
		const FHazeAkRTPC CharacterIsAirborne = FHazeAkRTPC("Rtpc_Player_Is_Airborne");
		const FHazeAkRTPC VOEffortsIsInAir = FHazeAkRTPC("Rtpc_VO_Efforts_Is_Airborne");
		const FHazeAkRTPC CharacterMovementType = FHazeAkRTPC("Rtpc_Player_Traversal_Type");
		const FHazeAkRTPC CharacterSkydiveDistanceToGround = FHazeAkRTPC("Rtpc_Player_Falling_DistanceToGround");		
		const FHazeAkRTPC CharacterObjectRelativeVelocityDelta = FHazeAkRTPC("Rtpc_Player_Object_Relative_Velocity_Delta");

		// Player VO
		const FString CodyBarksPanningRTPC = "Rtpc_VO_Narrative_InWorld_MainCharacters_Panning_Cody";
		const FString MayBarksPanningRTPC = "Rtpc_VO_Narrative_InWorld_MainCharacters_Panning_May";		

		// Abilities

		const FString FrozenOrbSpellGrowth = "Rtpc_Abilities_Spells_IceOrb_Growth";

		// Vehicles

		const FString RailCartBoost = "Rtpc_Vehicles_RailCart_IsBoosting";
		const FString RailCartWheelAngle = "Rtpc_Vehicles_RailCart_Wheel_Turn_Degrees";

		const FString GrindingSpeed = "Rtpc_Grinding_Speed";
		const FString GrindingSplineLengthPosition = "Rtpc_Grinding_Spline_Length_Position";

		const FString DinoCraneVerticalMovement = "Rtpc_Platform_Dinocube_Move_Vertical";
		const FString DinoCraneHorizontalMovement = "Rtpc_Platform_Dinocube_Move_Horizontal";
		const FString DinoCranePlatformSplineProgress = "Rtpc_Platform_Dinocube_Spline_Progress";
		const FString DinoCraneMovementVelocity = "Rtpc_Vehicles_GreenDino_Movement_Velocity";
		const FString DinoCraneHeadMovementVelocity = "Rtpc_Vehicles_GreenDino_Crane_Velocity";
		const FString DinoCraneHeadElevation = "Rtpc_Vehicles_GreenDino_Crane_Head_Elevation";
		const FString DinoCraneHeadFoldedElevation = "Rtpc_Dino_Crane_Head_Folded_Elevation";

		const FString MoonBaboonUFOElevationDelta = "Rtpc_Vehicles_UFO_Elevation_Delta";
		const FString MoonBaboonUFORotationDelta = "Rtpc_Vehicles_UFO_Rotation";
		const FString MoonBaboonUFOTiltAngle = "Rtpc_Vehicles_UFO_Tilt_Angle";
		const FString MoonBaboonUFOVelocityDelta = "Rtpc_Vehicles_UFO_Velocity";
		const FString PilotingUFOCameraZoom = "Rtpc_Vehicles_UFO_Distance_to_Camera";
		const FString PilotingUFOJoystickLR = "Rtpc_SpaceStation_Inter_UFO_Lever_Rotation_LeftRight";
		const FString PilotingUFOJoystickFB = "Rtpc_SpaceStation_Inter_UFO_Lever_Rotation_FrontBack";		
		
		// Gadgets

		const FString MarbleBallVelocity = "Rtpc_Gadgets_MarbleBall_OnRails_Velocity";
		const FString MarbleBallVelocityDelta = "Rtpc_Gadgets_MarbleBall_OnRails_VelocityDelta";
		const FString MarbleBallImpactForce = "Rtpc_Gadgets_MarbleBall_OnRails_ImpactForce";
		const FString MarbleBallIsFalling = "Rtpc_Gadgets_MarbleBall_OnRails_IsFalling";
		const FString SpaceConductorsConnected = "Rtpc_SpaceStation_Inter_SpaceConductor_Connections";
		const FString TractorBeamRotationAngle = "Rtpc_SpaceStation_Platform_TractorBeam_Angle";
		const FString TractorBeamRotationYaw = "Rtpc_SpaceStation_Platform_TractorBeam_Rotation";
		const FString TractorBeamRotationMoving = "Rtpc_SpaceStation_Platform_TractorBeam_Moving";
		const FString LaserSpinnerDistanceRTPC = "Rtpc_Weapon_LaserSpinner_DistanceToSpinner";
		const FString UFOLaserCannonLockOn = "Rtpc_Vehicles_UFO_Arcade_LockOn_Distance";

		// World

		const FString MoveObjectVelocity = "Rtpc_World_Shared_Move_Large_Object_Velocity";
		const FString MoveObjectImpactForce = "Rtpc_World_Shared_Move_Object_Impact_Force";		
		const FString HamsterWheelSpeed = "Rtpc_Goldberg_Circus_HamsterWheel_RotationVelocity";
		const FString RotatingObjectAngularVelocity = "Rtpc_World_Shared_Platform_Rotational_Angular_Velocity";
		const FString CircusStickControllerRotationSpeed = "Rtpc_Goldberg_Circus_CircusStickController_RotationVelocity";
		const FString SpaceStationMoonBaboonHangarAlarmLowPassRight = "Rtpc_SpaceStation_Hangar_Alarm_R_Lowpass";
		const FString WindupKeyTurnPercentage = "Rtpc_World_Shared_Interaction_Windup_Key_Turn_Progress";
		const FString WindupKeyTurnDelta = "Rtpc_World_Shared_Interaction_Windup_Key_Turn_Delta";	

		// Garden Plants

		const FString BeanstalkIsMoving = "Rtpc_Gameplay_Ability_ControllablePlant_Beanstalk_IsMoving";
		const FString BeanstalkAngularVelocity = "Rtpc_Gameplay_Ability_ControllablePlant_Beanstalk_AngularVelocity";
		const FString BeanstalkMovementDirection = "Rtpc_Gameplay_Ability_ControllablePlant_Beanstalk_MovementDirection";		
		const FString BeanstalkCurrentLength = "Rtpc_Gameplay_Ability_ControllablePlant_Beanstalk_Length";
		const FString BeanstalkLeafCount = "Rtpc_Gameplay_Ability_ControllablePlant_Beanstalk_Leaf_Count";
		const FString BeanstalkHeadTilt = "Rtpc_Gameplay_Ability_ControllablePlant_Beanstalk_Head_Tilt";
		const FString BeanstalkHeadTiltDelta = "Rtpc_Gameplay_Ability_ControllablePlant_Beanstalk_Head_Tilt_Delta";

		// Water Hose
		const FString WaterHoseFlowerFillAmount = "Rtpc_Gadget_WaterHose_Flower_FillAmount";
		const FString WaterHoseMovementSpeed = "Rtpc_Gadget_WaterHose_Movement_Speed";
		const FString WaterHoseSoilWetAmount = "Rtpc_Gadget_WaterHose_Soil_WetAmount";
		const FString WaterHosePurpleSapHitAmount = "Rtpc_Gadget_WaterHose_PurpleSap_HitAmount";		

		// Delay

		const FString EnvironmentType = "Rtpc_Environment_Type";

		// Health

		const FString PlayerHealthValue = "Rtpc_UI_Health_Value";
		const FString PlayerHealthDelta = "Rtpc_UI_Health_Delta";
		const FString RespawnProgressValue = "Rtpc_UI_Health_ReSpawnProg_Value";
		const FString HealthDecayStartAmount = "Rtpc_UI_Health_Decay_Start_Amount";		
	}

	namespace SWITCH
	{
		// Shared		

		const FString CharacterLifeStatusGroup = "Swgr_Character_Life_Status";
		const FString CharacterAlive = "Swtc_Character_Alive";
		const FString CharacterDead = "Swtc_Character_Dead";
		const FString CharacterRespawning = "Swtc_Character_Respawning";

		// Cody Castle Spells
		const FString OrbSpellSpeedGroup = "Swgr_Orb_Spell_Speed";
		const FString OrbSpellSpeedSlow = "Swtc_Orb_Spell_Speed_Slow";
		const FString OrbSpellSpeedFast = "Swtc_Orb_Spell_Speed_Fast";

		//Suit Types
		const FString MaySuitTypesGroup = "Swgr_May_Suit_Types";
		const FString MaySuitTypeNone = "Swgr_May_Suit_None";
		const FString MayBruteSuit = "Swtc_May_Brute_Suit";
		const FString MaySpaceBootsSuit = "Swtc_May_Space_Boots_Suit";

		const FString CodySuitTypesGroup = "Swgr_Cody_Suit_Types";
		const FString CodySuitTypeNone = "Swtc_Cody_Suit_None";

		// Surfaces

		const FString SurfaceMaterialsSwitchGroup = "Swgr_Materials_Surface";
		const FString SurfaceMaterialSwitchDefault = "Swtc_Surface_Default";
		const FString SurfaceMaterialSwitchGrass = "Swtc_Surface_Grass";

		// Player CharacterTraversalGroup

		const FString PlayerTraversalTypeSwitchGroup = "Swgr_Player_Traversal_Type";
		const FString PlayerTraversalTypeIdle = "Swtc_Player_Traversal_Idle";
		const FString PlayerTraversalTypeCrouch = "Swtc_Player_Traversal_Crouch";
		const FString PlayerTraversalTypeRun = "Swtc_Player_Traversal_Run";
		const FString PlayerTraversalTypeSprint = "Swtc_Player_Traversal_Sprint";
		const FString PlayerTraversalTypeSlide = "Swtc_Player_Traversal_Slide";
		const FString PlayerTraversalTypeGrind = "Swtc_Player_Traversal_Grind";
		const FString PlayerTraversalTypeFalling = "Swtc_Player_Traversal_Falling";
		const FString PlayerTraversalTypeSkydive = "Swtc_Player_Traversal_Skydive";
		const FString PlayerTraversalTypeHeavyWalk = "Swtc_Player_Traversal_HeavyWalk";
		const FString PlayerTraversalTypeSwimming = "Swtc_Player_Traversal_Swimming";
		const FString PlayerTraversalTypeSwing = "Swtc_Player_Traversal_Swing";
		const FString PlayerTraversalTypeIceSkating = "Swtc_Player_Traversal_IceSkating";	

		// Player Vegetation Group

		const FString PlayerVegetationTypeSwitchGroup = "Swgr_Player_Vegetation_Type";
		const FString PlayerVegetationTypeFern = "Swgr_Player_Vegetation_Fern";
		const FString PlayerVegetationTypeGrass = "Swgr_Player_Vegetation_Grass";
		const FString PlayerVegetationTypeNone = "Swtc_Player_Traversal_Non";
		const FString PlayerVegetationTypePlant = "Swtc_Player_Traversal_Plant";
	}

	namespace STATES
	{
		const FName LevelStateGroup = n"StateGroup_Levels";
		const FName LevelStateGroupDefault = n"Stt_Level_Default";

		const FName SubLevelStateGroup = n"StateGroup_SubLevels";
		const FName SubLevelStateGroupDefault = n"Stt_SubLevel_Default";

		const FName ProgressionStateGroup = n"StateGroup_Checkpoints";
		const FName ProgresstionStateGroupDefault = n"Stt_CheckPoints_Default";

		const FName CutsceneStateGroup = n"StateGroup_Cutscenes";
		const FName CutsceneStateGroupDefault = n"Stt_CS_Default";

		const FName DesignerCutsceneStateGroup = n"StateGroup_DesignerSequences";
		const FName DesignerCutsceneStateGroupDefault = n"Stt_DS_Default";

		const FName MenuStateGroup = n"StateGroup_Menu";
		const FName MenuStateDefault = n"Stt_Menu_Default";

		const FName GameplayStateGroup = n"StateGroup_Gameplay";
		const FName GameplayStateDefault = n"Stt_Gameplay_Default";

		const FName CheckpointStateGroup = n"StateGroup_Checkpoints";

		const FName MusicClassicMusicStateGroup = n"MStg_Music_Classic";
		const FName MusicClassicMusicStateMain = n"MStt_Music_Classic_Main";
		const FName MusicClassicMusicStateSilent = n"MStt_Music_Classic_Silent";

		const FName MusicStateGroupEnding = n"MStg_Music_Ending";
		const FName MusicStateGroupCastle = n"MStg_Playroom_Castle";
		const FName MusicStateGroupHopskotch = n"MStg_Playroom_Hopskotch";
		const FName MusicStateGroupGoldberg = n"MStg_Playroom_Goldberg";
		const FName MusicStateGroupSpaceStation = n"MStg_Playroom_Spacestation";
		const FName MusicStateGroupTree = n"MStg_Tree";
		const FName MusicStateGroupGarden = n"MStg_Garden";
		const FName MusicStateGroupSnowglobe = n"MStg_Snowglobe";
		const FName MusicStateGroupShed = n"MStg_Shed";

		const FName MusicSideContentMiniGamesStateGroup = n"MStg_SideContent_MiniGames";
		const FName MusicSideContentMiniGamesDefaultState = n"MStt_SideContent_MiniGames_Default";

		// MiniGames

		const FName MinigameLowDucking = n"Stt_Gameplay_Minigame_Low_Ducking";
		const FName MinigameMedDucking = n"Stt_Gameplay_Minigame_Med_Ducking";
		const FName MinigameHighDucking = n"Stt_Gameplay_Minigame_High_Ducking";
	}

	namespace StaticValues
	{
		const float MayDefaultSpeakerPanningLRValue = -0.4f;
		const float CodyDefaultSpeakerPanningLRValue = 0.4f;		
	}

	////////////////////////////////////////////////////////////////////////////////////////////////////////
	//									CONVERSIONS													  	  //	
	////////////////////////////////////////////////////////////////////////////////////////////////////////

	UFUNCTION(BlueprintCallable)
	float NormalizeRTPC01(float InValue, float InMinimum, float InMaximum)
	{
		return FMath::Clamp(FMath::Lerp(0.f, 1.f, Math::GetPercentageBetween(InMinimum, InMaximum, InValue)), 0.f, 1.f);
	}

	UFUNCTION(BlueprintCallable)
	float NormalizeRTPC(float InValue, float InMinimum, float InMaximum, float OutMinimum, float OutMaximum)
	{
		return FMath::Clamp(FMath::Lerp(OutMinimum, OutMaximum, Math::GetPercentageBetween(InMinimum, InMaximum, InValue)), OutMinimum, OutMaximum);
	}	

	////////////////////////////////////////////////////////////////////////////////////////////////////////
	//									LISTENER SPEAKER OFFSETS										  //	
	////////////////////////////////////////////////////////////////////////////////////////////////////////


	FHazeListenerSpeakerOffsets GetPlayerDefaultListenerSpeakerOffsets(AHazePlayerCharacter Player)
	{
		if(Player.IsMay())
			return UHazeListenerComponent::GetMayDefaultListenerSpeakerOffsets();
		else
			return UHazeListenerComponent::GetCodyDefaultListenerSpeakerOffsets();		
	}

}

namespace GardenAudioActions
{
	const FName SickleAreaEntered = n"AudioSickleAreaEntered";
	const FName SickleAreaExited = n"AudioSickleAreaExited";
	const FName SickleAreaCombatActivated = n"AudioSickleAreaCombatActivated";
	const FName SickleAreaCombatDeactivated = n"AudioSickleAreaCombatDeactivated";
	const FName SickleAreaAllEnemiesDefeated = n"AudioSickleAreaAllEnemiesDefeated";
	const FName ShieldedBuldExplosion = n"AudioShieldedBulbExplosion";
}
