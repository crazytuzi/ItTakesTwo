import Cake.Environment.Godray;
import Cake.LevelSpecific.Music.LevelMechanics.Backstage.LightRoom.LightRoomSpotlightLocationActor;
import Vino.PlayerHealth.PlayerHealthStatics;
import Peanuts.Audio.AudioStatics;

class ALightRoomSpotlight : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MovementRoot;
	
	UPROPERTY(DefaultComponent, Attach = MovementRoot)
	USceneComponent LeftSpotlightRoot;

	UPROPERTY(DefaultComponent, Attach = LeftSpotlightRoot)
	USpotLightComponent LeftSpotlight;

	UPROPERTY(DefaultComponent, Attach = LeftSpotlight)
	USceneComponent LeftFakeLightRoot;

	UPROPERTY(DefaultComponent, Attach = LeftFakeLightRoot)
	UStaticMeshComponent LeftFakeLight;

	UPROPERTY(DefaultComponent, Attach = LeftFakeLightRoot)
	UStaticMeshComponent LeftFakeLight2;

	UPROPERTY(DefaultComponent, Attach = MovementRoot)
	USceneComponent RightSpotlightRoot;

	UPROPERTY(DefaultComponent, Attach = RightSpotlightRoot)
	USpotLightComponent RightSpotlight;

	UPROPERTY(DefaultComponent, Attach = RightSpotlight)
	USceneComponent RightFakeLightRoot;

	UPROPERTY(DefaultComponent, Attach = RightFakeLightRoot)
	UStaticMeshComponent RightFakeLight;
	
	UPROPERTY(DefaultComponent, Attach = RightFakeLightRoot)
	UStaticMeshComponent RightFakeLight2;

	UPROPERTY(DefaultComponent, Attach = MovementRoot)
	UBoxComponent Box;
	default Box.bHiddenInGame = true;

	UPROPERTY(DefaultComponent, Attach = LeftSpotlightRoot)
	UHazeAkComponent LeftLightHazeAkComp;

	UPROPERTY(DefaultComponent, Attach = RightSpotlightRoot)
	UHazeAkComponent RightLightHazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ActivateRightSpotlightAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent LeftSpotlightMovementAudioEvent;

	UPROPERTY()
	ALightRoomSpotlightLocationActor LeftSpotlightLocationActor;

	UPROPERTY()
	ALightRoomSpotlightLocationActor RightSpotlightLocationActor;

	UPROPERTY()
	AActor GroundActor;

	UPROPERTY()
	AActor DirectionActor;

	AHazePlayerCharacter PlayerToFollow;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncVectorComponent SyncedRightLocation;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncVectorComponent SyncedLeftLocation;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncVectorComponent SyncedRootLocation;

	// For audio
	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent SyncedLeftSpotlightX;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent SyncedLeftSpotlightY;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent SyncedRightSpotlightX;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent SyncedRightSpotlightY;

	private float LastLeftYRtpc;
	private float LastLeftXRtpc;
	private float LastRightYRtpc;
	private float LastRightXRtpc;
	private FVector2D LastLeftSpotlightPos;
	private FVector2D LastRightSpotlightPos;

	bool bHasActivated = false;

	bool bDisableInput = false;

	float LengthToGround = 0.f;

	float LeftCurrentX;
	float LeftCurrentY;
	float LeftTargetX;
	float LeftTargetY;
	FVector2D CurrentLeftInput;

	float RightCurrentX;
	float RightCurrentY;
	float RightTargetX;
	float RightTargetY;
	FVector2D CurrentRightInput;

	float RollMin = -45.f;
	float RollMax = 45.f;
	float PitchMin = -45.f;
	float PitchMax = 45.f;

	float SpotlightInterpSpeed = 15.5f;
	float SpotlightMovementSpeed = 1750.f;

	float YPaddingOffset = 2.0f;

	float MaxY;
	float LeftMaxY;
	float MinY;
	float RightMinY;
	float MaxX;
	float MinX;

	float ReEnableInputTimer = 0.f;
	float ReEnableInputTimerDuration = 1.f;
	bool bShouldTickReEnableInputTimer = false;

	float SpotlightIntensity = 0.f;

	bool bRightSpotlightActivated = false;
	bool bPlayerToFollowIsDead = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		LengthToGround = (GroundActor.ActorLocation - ActorLocation).Size();
		
		SpotlightIntensity = LeftSpotlight.Intensity;
		
		LeftTargetX = LeftSpotlightLocationActor.ActorLocation.X;
		LeftTargetY = LeftSpotlightLocationActor.ActorLocation.Y;
		LeftCurrentX = LeftSpotlightLocationActor.ActorLocation.X;
		LeftCurrentY = LeftSpotlightLocationActor.ActorLocation.Y;

		RightTargetX = RightSpotlightLocationActor.ActorLocation.X;
		RightTargetY = RightSpotlightLocationActor.ActorLocation.Y;
		RightCurrentX = RightSpotlightLocationActor.ActorLocation.X;
		RightCurrentY = RightSpotlightLocationActor.ActorLocation.Y;

		RightSpotlight.SetIntensity(0.f);
		RightFakeLight.SetHiddenInGame(true);
		RightFakeLight2.SetHiddenInGame(true);
		RightSpotlightLocationActor.bIsProvidingLight = false;
		LeftSpotlightLocationActor.bIsProvidingLight = true;


		SyncedRootLocation.Value = MovementRoot.WorldLocation;
		SyncedRightLocation.Value = RightSpotlightLocationActor.ActorLocation;
		SyncedLeftLocation.Value = LeftSpotlightLocationActor.ActorLocation;

		LeftLightHazeAkComp.SetRTPCValue("Rtpc_World_Music_Backstage_Platform_LightRoomSpotLight_Input_X", 0);
		LeftLightHazeAkComp.SetRTPCValue("Rtpc_World_Music_Backstage_Platform_LightRoomSpotLight_Input_Y", 0);
		RightLightHazeAkComp.SetRTPCValue("Rtpc_World_Music_Backstage_Platform_LightRoomSpotLight_Input_X", 0);
		RightLightHazeAkComp.SetRTPCValue("Rtpc_World_Music_Backstage_Platform_LightRoomSpotLight_Input_Y", 0);
		LeftLightHazeAkComp.HazePostEvent(LeftSpotlightMovementAudioEvent);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(HasControl() && bHasActivated)
		{
			MaxX = (Box.WorldLocation + ActorForwardVector * Box.BoxExtent.X).X;
			MinX = (Box.WorldLocation + ActorForwardVector * -Box.BoxExtent.X).X;
			MaxY = (Box.WorldLocation + ActorRightVector * Box.BoxExtent.Y).Y;
			LeftMaxY = Box.WorldLocation.Y;
			MinY = (Box.WorldLocation + ActorRightVector * -Box.BoxExtent.Y).Y;
			RightMinY = Box.WorldLocation.Y;
			
			if (PlayerToFollow != nullptr)
			{
				if (!PlayerToFollow.IsPlayerDead())
				{
					UpdateLeftLocationActor(DeltaTime);
					UpdateRightLocationActor(DeltaTime);
				} 
			}

			if (bShouldTickReEnableInputTimer)
			{
				ReEnableInputTimer += DeltaTime;
				if (ReEnableInputTimer >= ReEnableInputTimerDuration)
				{
					bShouldTickReEnableInputTimer = false;
					bDisableInput = false;
				}
			}

			if (PlayerToFollow == nullptr)
				return;
			
			FVector NewLoc = FVector(PlayerToFollow.ActorLocation.X, PlayerToFollow.ActorLocation.Y, MovementRoot.WorldLocation.Z);
			MovementRoot.SetWorldLocation(NewLoc);

			SyncedRootLocation.Value = MovementRoot.WorldLocation;
			SyncedRightLocation.Value = RightSpotlightLocationActor.ActorLocation;
			SyncedLeftLocation.Value = LeftSpotlightLocationActor.ActorLocation;
		}
		else
		{
			if(bHasActivated)
			{
				MovementRoot.SetWorldLocation(SyncedRootLocation.Value);
				RightSpotlightLocationActor.SetActorLocation(SyncedRightLocation.Value);
				LeftSpotlightLocationActor.SetActorLocation(SyncedLeftLocation.Value);
			}
		}

		if(bHasActivated)
		{	
			{
				FVector Dir = LeftSpotlightLocationActor.ActorLocation - LeftSpotlight.WorldLocation;
				FRotator Rot = Dir.ToOrientationRotator();
				LeftSpotlight.WorldRotation = Rot;

				FVector2D LeftSpotlightPos;
				SceneView::ProjectWorldToScreenPosition(SceneView::GetFullScreenPlayer(), LeftSpotlightLocationActor.ActorLocation, LeftSpotlightPos);
				if(LeftSpotlightPos.X != LastLeftSpotlightPos.X)
				{				
					const float	NormalizedPanning = HazeAudio::NormalizeRTPC(LeftSpotlightPos.X, 0.f, 1.f, -1.f, 1.f);					

					HazeAudio::SetPlayerPanning(LeftLightHazeAkComp, nullptr, NormalizedPanning);
					LastLeftSpotlightPos = LeftSpotlightPos;
				}
	
			}

			if(LastLeftYRtpc != SyncedLeftSpotlightY.Value)
			{
				LeftLightHazeAkComp.SetRTPCValue("Rtpc_World_Music_Backstage_Platform_LightRoomSpotLight_Input_Y", SyncedLeftSpotlightY.Value);			
				LastLeftYRtpc = SyncedLeftSpotlightY.Value;

			}

			if(LastLeftXRtpc != SyncedLeftSpotlightX.Value)
			{
				LeftLightHazeAkComp.SetRTPCValue("Rtpc_World_Music_Backstage_Platform_LightRoomSpotLight_Input_X", SyncedLeftSpotlightX.Value);
				LastLeftXRtpc = SyncedLeftSpotlightX.Value;
			}


			if(bRightSpotlightActivated)
			{
				FVector Dir = RightSpotlightLocationActor.ActorLocation - RightSpotlight.WorldLocation;
				FRotator Rot = Dir.ToOrientationRotator();
				RightSpotlight.WorldRotation = Rot;	

				if(LastRightXRtpc != SyncedRightSpotlightX.Value)
				{
					RightLightHazeAkComp.SetRTPCValue("Rtpc_World_Music_Backstage_Platform_LightRoomSpotLight_Input_X", SyncedRightSpotlightX.Value);
					LastRightXRtpc = SyncedRightSpotlightX.Value;
				}	

				if(LastRightYRtpc != SyncedRightSpotlightY.Value)
				{
					RightLightHazeAkComp.SetRTPCValue("Rtpc_World_Music_Backstage_Platform_LightRoomSpotLight_Input_Y", SyncedRightSpotlightY.Value);
					LastRightYRtpc = SyncedRightSpotlightY.Value;
				}

				FVector2D RightSpotlightPos;
				SceneView::ProjectWorldToScreenPosition(SceneView::GetFullScreenPlayer(), RightSpotlightLocationActor.ActorLocation, RightSpotlightPos);
				if(RightSpotlightPos.X != LastRightSpotlightPos.X)
				{
					const float NormalizedPanning = HazeAudio::NormalizeRTPC(RightSpotlightPos.X, 0.5f, 1.f, 0.f, 1.f);
					HazeAudio::SetPlayerPanning(RightLightHazeAkComp, nullptr, NormalizedPanning);
					LastRightSpotlightPos = RightSpotlightPos;
				}			
			}
		}
	}

	void ChangeControlSide(UObject NewControlSide)
	{
		SetControlSide(NewControlSide);
		LeftSpotlightLocationActor.SetControlSide(NewControlSide);
		RightSpotlightLocationActor.SetControlSide(NewControlSide);
		bHasActivated = true;
	}

	UFUNCTION()
	void UpdatePlayerToFollow(AHazePlayerCharacter Player)
	{
		PlayerToFollow = Player;
		UPlayerRespawnComponent::Get(Player).OnRespawn.AddUFunction(this, n"PlayerToFollowRespawned");

		FOnPlayerDied PlayerDiedDelegate;
		PlayerDiedDelegate.BindUFunction(this, n"PlayerDied");
		BindOnPlayerDiedEvent(PlayerDiedDelegate);
	}

	UFUNCTION()
	void PlayerDied(AHazePlayerCharacter Player)
	{
		SetSpotlightsActive(false);
	}

	UFUNCTION()
	void PlayerToFollowRespawned(AHazePlayerCharacter Player)
	{
		SetSpotlightsActive(true);
		LocationActorFollowPlayer();
	}

	void UpdateLeftLocationActor(float DeltaTime)
	{
		LeftTargetY += (CurrentLeftInput.X * SpotlightMovementSpeed) * DeltaTime;
		LeftTargetX += (CurrentLeftInput.Y * SpotlightMovementSpeed) * DeltaTime;
		LeftTargetX = FMath::Min(LeftTargetX, MaxX);
		LeftTargetX = FMath::Max(LeftTargetX, MinX);
		LeftTargetY = FMath::Max(LeftTargetY, MinY);

		
		if (bRightSpotlightActivated)
			LeftTargetY = FMath::Min(LeftTargetY, LeftMaxY - YPaddingOffset);
		else
			LeftTargetY = FMath::Min(LeftTargetY, MaxY);

		LeftCurrentX = FMath::FInterpTo(LeftCurrentX, LeftTargetX, DeltaTime, SpotlightInterpSpeed);
		LeftCurrentY = FMath::FInterpTo(LeftCurrentY, LeftTargetY, DeltaTime, SpotlightInterpSpeed);

		LeftSpotlightLocationActor.SetActorLocation(FVector(LeftCurrentX, LeftCurrentY, LeftSpotlightLocationActor.ActorLocation.Z));
	}

	void UpdateRightLocationActor(float DeltaTime)
	{
		RightTargetY += (CurrentRightInput.X * SpotlightMovementSpeed) * DeltaTime;
		RightTargetX += (CurrentRightInput.Y * SpotlightMovementSpeed) * DeltaTime;
		RightTargetX = FMath::Min(RightTargetX, MaxX);
		RightTargetX = FMath::Max(RightTargetX, MinX);
		RightTargetY = FMath::Min(RightTargetY, MaxY);
		RightTargetY = FMath::Max(RightTargetY, RightMinY + YPaddingOffset);

		RightCurrentX = FMath::FInterpTo(RightCurrentX, RightTargetX, DeltaTime, SpotlightInterpSpeed);
		RightCurrentY = FMath::FInterpTo(RightCurrentY, RightTargetY, DeltaTime, SpotlightInterpSpeed);



		if(!bRightSpotlightActivated)
		{
			if (PlayerToFollow != nullptr)
			{				
				RightSpotlightLocationActor.SetActorLocation(PlayerToFollow.ActorLocation);
				RightTargetX = RightSpotlightLocationActor.ActorLocation.X;
				RightTargetY = RightSpotlightLocationActor.ActorLocation.Y;
				RightCurrentX = RightSpotlightLocationActor.ActorLocation.X;
				RightCurrentY = RightSpotlightLocationActor.ActorLocation.Y;
			}
		}

		RightSpotlightLocationActor.SetActorLocation(FVector(RightCurrentX, RightCurrentY, RightSpotlightLocationActor.ActorLocation.Z));	
	}

	void SetSpotlightsActive(bool bActivate)
	{
		if (bActivate)
		{
			bDisableInput = true;
			ReEnableInputTimer = 0.f;
			bShouldTickReEnableInputTimer = true;
			LeftSpotlight.SetIntensity(SpotlightIntensity);
			LeftFakeLight.SetHiddenInGame(false);
			LeftFakeLight2.SetHiddenInGame(false);
			bPlayerToFollowIsDead = true;
			
			if (bRightSpotlightActivated)
			{
				RightSpotlight.SetIntensity(SpotlightIntensity);
				RightFakeLight.SetHiddenInGame(false);
				RightFakeLight2.SetHiddenInGame(false);
			}
		}

		if (!bActivate)
		{
			LeftSpotlight.SetIntensity(0.f);
			RightSpotlight.SetIntensity(0.f);
			LeftFakeLight.SetHiddenInGame(true);
			LeftFakeLight2.SetHiddenInGame(true);
			RightFakeLight.SetHiddenInGame(true);
			RightFakeLight2.SetHiddenInGame(true);
			bPlayerToFollowIsDead = false;
		}
	}

	void LocationActorFollowPlayer()
	{
		LeftSpotlightLocationActor.SetActorLocation(PlayerToFollow.ActorLocation);
		LeftTargetX = LeftSpotlightLocationActor.ActorLocation.X;
		LeftTargetY = LeftSpotlightLocationActor.ActorLocation.Y;
		LeftCurrentX = LeftSpotlightLocationActor.ActorLocation.X;
		LeftCurrentY = LeftSpotlightLocationActor.ActorLocation.Y;

		RightSpotlightLocationActor.SetActorLocation(PlayerToFollow.ActorLocation);
		RightTargetX = RightSpotlightLocationActor.ActorLocation.X;
		RightTargetY = RightSpotlightLocationActor.ActorLocation.Y;
		RightCurrentX = RightSpotlightLocationActor.ActorLocation.X;
		RightCurrentY = RightSpotlightLocationActor.ActorLocation.Y;
	}

	float ForwardLengthToGround(USpotLightComponent Spotlight)
	{
		float Rad = Spotlight.ForwardVector.AngularDistance(ActorUpVector * -1.f);		
		float ForwardLengthToGround = LengthToGround / FMath::Cos(Rad);
		return ForwardLengthToGround;
	}

	void CurrentInput(FVector LeftInput, FVector RightInput)
	{
		if (bDisableInput)
		{
			CurrentLeftInput.X = 0.f;
			CurrentLeftInput.Y = 0.f;
			CurrentRightInput.X = 0.f;
			CurrentRightInput.Y = 0.f;	
		} else 
		{
			CurrentLeftInput.X = LeftInput.X;
			CurrentLeftInput.Y = LeftInput.Y;
			CurrentRightInput.X = RightInput.X;
			CurrentRightInput.Y = RightInput.Y;
		}

		SyncedLeftSpotlightY.Value = CurrentLeftInput.Y;
		SyncedLeftSpotlightX.Value = CurrentLeftInput.X;
		SyncedRightSpotlightY.Value = CurrentRightInput.Y;
		SyncedRightSpotlightX.Value = CurrentRightInput.X;
	}

	UFUNCTION()
	void ActivateRightSpotlight()
	{
		RightSpotlight.SetIntensity(SpotlightIntensity);
		RightFakeLight.SetHiddenInGame(false);
		RightFakeLight2.SetHiddenInGame(false);
		RightSpotlightLocationActor.bIsProvidingLight = true;
		bRightSpotlightActivated = true;
		
		RightLightHazeAkComp.HazePostEvent(ActivateRightSpotlightAudioEvent);
	}
}
