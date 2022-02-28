import Vino.Movement.Components.GroundPound.GroundpoundedCallbackComponent;
import Cake.Environment.GPUSimulations.PaperPainting;
import Cake.LevelSpecific.PlayRoom.Castle.Courtyard.SideContent.Painting.PaintingPrinterButtonActor;
import Vino.Interactions.AnimNotify_Interaction;
import Cake.LevelSpecific.PlayRoom.Castle.Courtyard.SideContent.Painting.PaintingTravellingImageActor;
import Vino.Movement.MovementSettings;

class APaintingAreaActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent PoolTrigger;

	UPROPERTY(DefaultComponent)
	UGroundPoundedCallbackComponent GroundPoundComp;

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	APaperPainting PaintingActor;

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	APaintingPrinterButtonActor PrintButton;

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	APaintingPrinterButtonActor SaveButton;

	UPROPERTY(Category = "Setup")
	APaintingTravellingImageActor PaintingTravellingImageActor;
	
	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent PaperMesh;

	UPROPERTY()
	UMaterialInstanceDynamic PaperMeshMaterial;

	UPROPERTY(Category = "Setup")
	UNiagaraSystem EnterPoolSystem;
	UPROPERTY(Category = "Setup")
	UNiagaraSystem LeavePoolSystem;
	UPROPERTY(Category = "Setup")
	ATargetPoint SaveCanvasTargetPoint;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent MayEnterPool;
	UPROPERTY(Category = "Audio")
	UAkAudioEvent MayExitPool;
	UPROPERTY(Category = "Audio")
	UAkAudioEvent CodyEnterPool;
	UPROPERTY(Category = "Audio")
	UAkAudioEvent CodyExitPool;

	//Change to callback from fade complete
	FTimerHandle SaveTimer;

	FHazeAnimNotifyDelegate AnimNotifyDelegate;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike CodyPaintTimeLike;
	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike MayPaintTimeLike;

	FVector PictureCentreLocation = FVector(3469.f, 59193.f, -80.f);

	float PlayPoolSpeed = 600.f;
	TPerPlayer<FHazeAcceleratedFloat> AccelPoolAudioValue;

	TPerPlayer<AHazePlayerCharacter> Players;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GroundPoundComp.OnActorGroundPounded.AddUFunction(this, n"OnGroundPounded");

		//Rework in conjuction with logic in paperpainting to preferably not require outside logic setting material.
		if(PaintingActor != nullptr)
			PaintingActor.PaperMeshSurfaceMaterialDynamic = MeshComp.CreateDynamicMaterialInstance(0);
		
		if(SaveButton != nullptr)
			SaveButton.OnGroundPounded.AddUFunction(this, n"OnSavePainting");

		PaintingTravellingImageActor.OnPaintingImageReachedDestination.AddUFunction(this, n"PaintingReachedCanvas");

		PoolTrigger.OnComponentBeginOverlap.AddUFunction(this, n"OnPoolTriggerOverlap");
		PoolTrigger.OnComponentEndOverlap.AddUFunction(this, n"OnPoolTriggerEndOverlap");

		CodyPaintTimeLike.BindUpdate(this, n"CodyTimeLikeUpdate");
		CodyPaintTimeLike.BindFinished(this, n"CodyTimeLikeFinished");

		MayPaintTimeLike.BindUpdate(this, n"MayTimeLikeUpdate");
		MayPaintTimeLike.BindFinished(this, n"MayTimeLikeFinished");

		PaintingActor.InitPrinterPaper(PaperMesh);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (PaintingActor.PlayerData[1].bPlayerIsInPool && Players[0] != nullptr)
		{
			float RTCPValue = Players[0].MovementComponent.Velocity.Size() / PlayPoolSpeed;
			AccelPoolAudioValue[0].AccelerateTo(RTCPValue, 1.f, DeltaTime);
			Players[0].PlayerHazeAkComp.SetRTPCValue("Rtpc_Playroom_Courtyard_Painting_PoolMovement", AccelPoolAudioValue[0].Value);
		}

		if (PaintingActor.PlayerData[0].bPlayerIsInPool && Players[1] != nullptr)
		{
			float RTCPValue = Players[1].MovementComponent.Velocity.Size() / PlayPoolSpeed;
			AccelPoolAudioValue[1].AccelerateTo(RTCPValue, 1.f, DeltaTime);
			Players[1].PlayerHazeAkComp.SetRTPCValue("Rtpc_Playroom_Courtyard_Painting_PoolMovement", AccelPoolAudioValue[1].Value);
		}
	}

	UFUNCTION()
	void OnPoolTriggerOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex, bool bFromSweep, FHitResult& Hit)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

		if(Player != nullptr)
		{
			UMovementSettings::SetMoveSpeed(Player, PlayPoolSpeed, this);

			Niagara::SpawnSystemAtLocation(EnterPoolSystem, Player.ActorLocation);
			
			Players[Player] = Player;

			if(Player.IsCody())
				Player.PlayerHazeAkComp.HazePostEvent(CodyEnterPool);
			else
				Player.PlayerHazeAkComp.HazePostEvent(MayEnterPool);

			if(Player.IsCody())
				PaintingActor.PlayerData[0].bPlayerIsInPool = true;
			else
				PaintingActor.PlayerData[1].bPlayerIsInPool = true;
		}
	}

	UFUNCTION()
	void OnPoolTriggerEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

		if(Player != nullptr)
		{
			UMovementSettings::ClearMoveSpeed(Player, this);

			Niagara::SpawnSystemAtLocation(LeavePoolSystem, Player.ActorLocation);

			if(Player.IsCody())
				Player.PlayerHazeAkComp.HazePostEvent(CodyExitPool);
			else
				Player.PlayerHazeAkComp.HazePostEvent(MayExitPool);

			if(Player.IsCody())
			{
				CodyPaintTimeLike.PlayFromStart();
				PaintingActor.PlayerData[0].bPlayerIsInPool = false;
			}
			else
			{
				MayPaintTimeLike.PlayFromStart();

				PaintingActor.PlayerData[1].bPlayerIsInPool = false;
			}
		}
	}

	UFUNCTION()
	void OnGroundPounded(AHazePlayerCharacter Player)
	{
		if(PaintingActor == nullptr)
			return;

		if(PoolTrigger.IsOverlappingActor(Player))
		{
			PaintingActor.GroundPound(Player, true, Player.ActorLocation, 0);
		}
		else
		{
			PaintingActor.GroundPound(Player, false, Player.ActorLocation, 0);
		}

		if(Player.IsCody())
			CodyPaintTimeLike.Stop();
		else
			MayPaintTimeLike.Stop();
	}

	UFUNCTION()
	void OnSavePainting(AHazePlayerCharacter Player)
	{
		// PaintingActor.CopyRectangleToPictureFrame(PictureCentreLocation, 0.25f, 0.35f);
		PaintingTravellingImageActor.ActivateAndSetPath();
		PaintingActor.CopyRectangle(PictureCentreLocation, 0.25f, 0.35f);
		PaintingActor.ClearRectangleOnPaper(PictureCentreLocation, 0.25f, 0.35f, FLinearColor::White);

		FHazePointOfInterest PoI;
		PoI.FocusTarget.Actor = SaveCanvasTargetPoint;
		PoI.Duration = 1.5f;
		PoI.Blend.BlendTime = 1.2f;
		Player.ApplyPointOfInterest(PoI, this);
	}

	UFUNCTION()
	void PaintingReachedCanvas()
	{
		PaintingActor.PasteToPictureFrame();
		SaveTimer = System::SetTimer(this, n"ResetSaveButton", 4.f, bLooping = false);
	}

	UFUNCTION()
	void ResetPrintButton()
	{
		PrintButton.ResetButton();
	}

	UFUNCTION()
	void ResetSaveButton()
	{
		SaveButton.ResetButton();
		System::ClearAndInvalidateTimerHandle(SaveTimer);
	}

	UFUNCTION()
	void CodyTimeLikeUpdate(float Value)
	{
		float NewValue = FMath::Lerp(1.f, 0.f, Value);

		AHazePlayerCharacter Player = Game::GetCody();

		PaintingActor.SetPlayerBrushOpacity(Player, Value);
		PaintingActor.SetPlayerBrushSize(Player, Value);
	}

	UFUNCTION()
	void CodyTimeLikeFinished()
	{
		PaintingActor.ClearPlayerPaint(Game::GetCody());
	}

	UFUNCTION()
	void StopCodyTimeLike()
	{
		CodyPaintTimeLike.Stop();
	}

	UFUNCTION()
	void MayTimeLikeUpdate(float Value)
	{
		float NewValue = FMath::Lerp(1.f, 0.f, Value);

		AHazePlayerCharacter Player = Game::GetMay();

		PaintingActor.SetPlayerBrushOpacity(Player, Value);
		PaintingActor.SetPlayerBrushSize(Player, Value);
	}

	UFUNCTION()
	void MayTimeLikeFinished()
	{
		PaintingActor.ClearPlayerPaint(Game::GetMay());
	}
	
	UFUNCTION()
	void StopMayTimeLike()
	{
		MayPaintTimeLike.Stop();
	}
}