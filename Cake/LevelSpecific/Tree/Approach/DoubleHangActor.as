
event void FOnHangDoorLockedOpen(AHazePlayerCharacter Player);
event void FOnPlayerHangAloneTooLong(AHazePlayerCharacter Player);
class ADoubleHangActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UHazeAkComponent HazeAkCompHandles;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkCompDoor;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent OnGrabHandlesAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent OnGrabDoorAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent OnReleaseHandlesAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent OnReleaseDoorAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent OnOpenbHandlesAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent OnOpenDoorAudioEvent;

	UPROPERTY(Meta = (MakeEditWidget))
	FVector HangDownPositionTwoPlayers;
	UPROPERTY(Meta = (MakeEditWidget))
	FVector HangDownPositionOnePlayer;

	UPROPERTY()
	FOnHangDoorLockedOpen OnFullyOpen;
	UPROPERTY()
	FOnPlayerHangAloneTooLong OnPlayerHangAloneTooLong;

	FHazeAcceleratedVector HangActorAcceleratedVector;


	AHazePlayerCharacter LastPlayerToJumpOn;

	bool bMayHanging = false;
	bool bCodyHanging = false;
	bool bForcedOpen = false;


	float LerpSpeed = 1;

	bool bAllowTriggerVoAloneHang = true;
	float HangAloneTime = 0;

	FVector HangDownPositionWorldTwoPlayers;
	FVector HangDownPositionWorldOnePlayer;
	FVector StartPositionWorld;


	UFUNCTION()
	float GetPercentage() property
	{
		float DistanceToEnd = StartPositionWorld.Distance(HangDownPositionWorldTwoPlayers);
		float DistanceToPos = StartPositionWorld.Distance(ActorLocation);

		return DistanceToPos / DistanceToEnd;
	}


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HangActorAcceleratedVector.Value = GetActorLocation();
		HangDownPositionWorldTwoPlayers = HangDownPositionTwoPlayers + GetActorLocation();
		HangDownPositionWorldOnePlayer = HangDownPositionOnePlayer + GetActorLocation();
		StartPositionWorld =  GetActorLocation();
	}

	UFUNCTION()
	void PlayerReleased(AHazePlayerCharacter Player)
	{
		if (Player.IsCody())
		{
			bCodyHanging = false;
			Player.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		}

		else
		{
			bMayHanging = false;
			Player.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		}

		HazeAkCompHandles.HazePostEvent(OnReleaseHandlesAudioEvent);
		HazeAkCompDoor.HazePostEvent(OnReleaseDoorAudioEvent);
	}

	UFUNCTION()
	void PlayerGrabbed(AHazePlayerCharacter Player)
	{
		LastPlayerToJumpOn = Player;

		if (Player.IsCody())
		{
			bCodyHanging = true;
			Player.AttachToActor(this, AttachmentRule = EAttachmentRule::KeepWorld);
		}
		else
		{
			bMayHanging = true;
			Player.AttachToActor(this, AttachmentRule = EAttachmentRule::KeepWorld);
		}

		if ((bMayHanging && !bCodyHanging) || (!bMayHanging && bCodyHanging))
		{
			HazeAkCompHandles.HazePostEvent(OnGrabHandlesAudioEvent);
			HazeAkCompDoor.HazePostEvent(OnGrabDoorAudioEvent);
		}
			
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float Deltatime)
	{
		FVector DesiredHangPosition;

		if(!bForcedOpen)
		{
		//	PrintToScreen("HangAloneTime " + HangAloneTime);
			if(bCodyHanging && bMayHanging)
			{
				HangAloneTime = 0;
				DesiredHangPosition = HangDownPositionWorldTwoPlayers;

				if(HangActorAcceleratedVector.Value.Z >= HangDownPositionWorldTwoPlayers.Z)
				{
					if(HasControl())
					{
						NetSetFullyOpen(LastPlayerToJumpOn);
					}
				}
			}
			else if(bCodyHanging || bMayHanging)
			{
				LerpSpeed = 1.0f;
				DesiredHangPosition = HangDownPositionWorldOnePlayer;

				if(bAllowTriggerVoAloneHang)
				{
					HangAloneTime += Deltatime;
					if(HangAloneTime >= 2)
					{
						if(bCodyHanging)
						{
							if(Game::GetCody().HasControl())
								PostHangAloneVO(Game::GetCody());
						}
						else if(bMayHanging)
						{
							if(Game::GetMay().HasControl())
								PostHangAloneVO(Game::GetMay());
						}
					}
				}
			}
			else
			{
				LerpSpeed = 1.0f;
				DesiredHangPosition = StartPositionWorld;
				HangAloneTime = 0; 
			}
		}
		else
		{
			HangAloneTime = 0;
			LerpSpeed = 0.15f;
			DesiredHangPosition = HangDownPositionWorldTwoPlayers;
		}

		HangActorAcceleratedVector.SpringTo(DesiredHangPosition, 25 * LerpSpeed, 1.0, Deltatime);
		SetActorLocation(HangActorAcceleratedVector.Value);
	}

	UFUNCTION(NetFunction)
	void PostHangAloneVO(AHazePlayerCharacter Player)
	{
		OnPlayerHangAloneTooLong.Broadcast(Player);
		bAllowTriggerVoAloneHang = false;
	}

	UFUNCTION(NetFunction)
	void NetSetFullyOpen(AHazePlayerCharacter LastPlayer)
	{
		bForcedOpen = true;
		OnFullyOpen.Broadcast(LastPlayer);

		HazeAkCompHandles.HazePostEvent(OnOpenbHandlesAudioEvent);
		HazeAkCompDoor.HazePostEvent(OnOpenDoorAudioEvent);
	}
}