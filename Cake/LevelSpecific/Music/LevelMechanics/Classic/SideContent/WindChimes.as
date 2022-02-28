import Vino.Movement.Swinging.SwingPoint;

class AWindChimes : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USkeletalMeshComponent MeshBody;

	UPROPERTY(DefaultComponent)
	UBillboardComponent Billboard;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent HazeDisable;
	default HazeDisable.bRenderWhileDisabled = true;
	default HazeDisable.bAutoDisable = true;
	default HazeDisable.AutoDisableRange = 10000.f;

	UPROPERTY()
	ASwingPoint SwingPoint;

	int PlayerInt;
	bool SoundPlaying = false;
	float DistanceFromTarget;

	//Variable to compute blendspace value
	UPROPERTY(BlueprintReadOnly)
	float DistanceFromCenter;

	//Variable to compute blendspace value
	UPROPERTY(BlueprintReadOnly)
	FVector ForwardVectorToTarget;

	//Bool to know if attached
	UPROPERTY(BlueprintReadOnly)
	bool HasEntered;

	//Bool to know if detached
	UPROPERTY(BlueprintReadOnly)
	bool HasExited;

	AHazePlayerCharacter MainPlayer;

	UPROPERTY(DefaultComponent, NotVisible)
	UHazeAkComponent HazeAkComp;	

	UPROPERTY(Category = "Audio")
	UAkAudioEvent OnStartSwinging;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent OnStopSwinging;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent StartSwingingLoopEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent StopSwingingLoopEvent;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(SwingPoint == nullptr)
			return; 
			
		SwingPoint.OnSwingPointAttached.AddUFunction(this, n"OnPlayerAttached");
		SwingPoint.OnSwingPointDetached.AddUFunction(this, n"OnPlayerDetached");
		SwingPoint.AttachToComponent(MeshBody, MeshBody.GetSocketBoneName(n"String12"), EAttachmentRule::SnapToTarget, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
		SwingPoint.AddActorLocalOffset(FVector(0, 0, -207));
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(MainPlayer == nullptr)
			return;

		DistanceFromTarget = (Billboard.GetWorldLocation()  - MainPlayer.GetActorLocation()).Size();
		DistanceFromCenter = DistanceFromTarget/800;
		ForwardVectorToTarget = (Billboard.GetWorldLocation() - MainPlayer.GetActorLocation());
		ForwardVectorToTarget.Normalize();
		//Make rotation local
		ForwardVectorToTarget = Billboard.GetWorldRotation().UnrotateVector(ForwardVectorToTarget);

		//Print("PlayerInt   "+ PlayerInt);
		//Print("SoundPlaying   "+ SoundPlaying);
		//Print("MainPlayer  " + MainPlayer);
		//Print("DistanceFromTarget  " + DistanceFromTarget);
		//Print("DistanceFromCenter  " + DistanceFromCenter);
		//Print("ForwardVectorToTarget  " + ForwardVectorToTarget);
	}

	UFUNCTION()
	void OnPlayerAttached(AHazePlayerCharacter Player)
	{
		if(Player.HasControl())
		{
			NetAddPlayer(Player);
			//Set correct bool values
			HasEntered = true;
			HasExited = false;
		}
		
	}
	UFUNCTION()
	void OnPlayerDetached(AHazePlayerCharacter Player)
	{
		if(Player.HasControl())
		{
			NetRemovePlayer(Player);
		}
	}

	UFUNCTION(NetFunction)
	void NetAddPlayer(AHazePlayerCharacter Player)
	{
		PlayerInt ++;
		CheckPlayers(Player);

		if(MainPlayer == nullptr)
		{
			MainPlayer = Player;
		}

		Player.PlayerHazeAkComp.HazePostEvent(OnStartSwinging);
	}
	UFUNCTION(NetFunction)
	void NetRemovePlayer(AHazePlayerCharacter Player)
	{
		PlayerInt --;
		CheckPlayers(Player);

		if(PlayerInt == 0)
		{
			MainPlayer = nullptr;
			HasExited = true;
			HasEntered = false;
		}
		if(PlayerInt == 1)
		{
			if(Player == Game::GetCody())
			{
				MainPlayer = Game::GetMay();
			}
			else
			{
				MainPlayer = Game::GetCody();
			}
		}

		Player.PlayerHazeAkComp.HazePostEvent(OnStopSwinging);
	}

	UFUNCTION()
	void CheckPlayers(AHazePlayerCharacter Player)
	{	
		if(PlayerInt == 0)
		{
			SoundPlaying = false;	
			HazeAkComp.HazePostEvent(StopSwingingLoopEvent);
			//stop audio
		}
		else if(PlayerInt == 1)
		{
			if(SoundPlaying == false)
			{
				SoundPlaying = true;
				HazeAkComp.HazePostEvent(StartSwingingLoopEvent);
				//Start audio
			}
		}
	}
}

