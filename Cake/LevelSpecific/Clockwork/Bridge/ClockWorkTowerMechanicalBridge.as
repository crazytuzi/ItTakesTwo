
struct FClockWorkTowerMechanicalBridgePieceConstructionData
{
	UPROPERTY(EditDefaultsOnly)
	UStaticMesh Mesh;
	
	UPROPERTY(EditDefaultsOnly)
	FRotator RelativeRotation;

	UPROPERTY(EditDefaultsOnly)
	float StartingDistanceOffset;

	UPROPERTY(EditDefaultsOnly)
	FVector Offset; 
}

// The AudioStruct for the bride
struct FClockWorkTowerMechanicalBridgeAkData
{
	UHazeAkComponent AkComponent;
	int PitchAmount = 0;
	bool bHasStartedPlayingSound = false; 
	bool bHasPlayedTopSound = false;
	float AudioVelocity = 0;
}

UCLASS(Abstract)
class AClockWorkTowerMechanicalBridge : AHazeActor
{
	default SetActorTickEnabled(false);
	default PrimaryActorTick.TickGroup = ETickingGroup::TG_PostPhysics;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	default Root.bVisualizeComponent = true;

	UPROPERTY(DefaultComponent, Attach = Root)
	UArrowComponent Arrow;
	default Arrow.SetWorldScale3D(FVector(30, 30, 30));
	default Arrow.bIsEditorOnly = true;
	default Arrow.bHiddenInGame = true;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent GroundCollision;
	default GroundCollision.bGenerateOverlapEvents = false;
	default GroundCollision.SetCollisionProfileName(n"BlockAll");
	default GroundCollision.BoxExtent = FVector(1000, 500, 100);

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent ActivationBounds;
	default ActivationBounds.bGenerateOverlapEvents = true;
	default ActivationBounds.SetCollisionProfileName(n"Trigger");
	default ActivationBounds.BoxExtent = FVector(2000, 1000, 2000);

	UPROPERTY(EditDefaultsOnly, Category = "Default")
	FClockWorkTowerMechanicalBridgePieceConstructionData LeftData;

	UPROPERTY(EditDefaultsOnly, Category = "Default")
	FClockWorkTowerMechanicalBridgePieceConstructionData RightData;

	UPROPERTY(EditDefaultsOnly, Category = "Default")
	FClockWorkTowerMechanicalBridgePieceConstructionData LeftShaftData;

	UPROPERTY(EditDefaultsOnly, Category = "Default")
	FClockWorkTowerMechanicalBridgePieceConstructionData RightShaftData;
	
	UPROPERTY(Category = "Default")
	int PieceAmount = 0;

	// The pitch amount for the ak component
	UPROPERTY(Category = "Audio")
	float PitchStartAmount = 0;

	// The pitch increase amount for each piece
	UPROPERTY(Category = "Audio")
	float PitchIncreaseAmount = 1;

	UPROPERTY(EditDefaultsOnly, Category = "Audio")
	UAkAudioEvent MovingSound;

	UPROPERTY(EditDefaultsOnly, Category = "Audio")
	UAkAudioEvent StopSound;

	UPROPERTY(EditDefaultsOnly, Category = "Audio")
	UAkAudioEvent ReachedTopSound;

	UPROPERTY(EditConst)
	TArray<UClockWorkTowerMechanicalBridgePiece> Pieces;

	UPROPERTY(EditConst)
	TArray<UClockWorkTowerMechanicalBridgeDriveShaft> Shafts;

	UPROPERTY(Transient, EditConst)
	TArray<FClockWorkTowerMechanicalBridgeAkData> AkComponents;
	
	const FVector2D ActivationRangeRange = FVector2D(FMath::Square(495.f), FMath::Square(2250.f));
	TArray<AHazePlayerCharacter> OverlappingPlayers;
	bool bPiecesWantActorToBeActive = false;

    UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
		Arrow.SetWorldRotation(GetActorForwardVector().ToOrientationRotator());
		
		if(PieceAmount % 2 != 0)
			PieceAmount += 1;

		// Pieces
		for(int i = 0; i < Pieces.Num(); ++i)
		{
			if(Pieces[i] != nullptr)
				Pieces[i].DestroyComponent(this);
		}
		Pieces.Reset(PieceAmount);

		// Shafts
		for(int i = 0; i < Shafts.Num(); ++i)
		{
			if(Shafts[i] != nullptr)
				Shafts[i].DestroyComponent(this);
		}
		Shafts.Reset(PieceAmount);

		

		for(int i = 0; i < PieceAmount; ++i)
		{	
			const bool bIsLeft = i % 2 == 0;
			const FString LeftName = bIsLeft ? "Left_" : "Right_";

			// Create the floor pieces
			{
				const auto& ConstructionData = bIsLeft ? LeftData : RightData;
				auto NewComp = Cast<UClockWorkTowerMechanicalBridgePiece>(CreateComponent(UClockWorkTowerMechanicalBridgePiece::StaticClass(), FName(LeftName + "Piece_" + i / 2)));
				NewComp.bIsLeft = bIsLeft;

				FVector Offset;
				Offset.X = ConstructionData.StartingDistanceOffset;
				Offset.X += i * ConstructionData.Offset.X;
				Offset.Y = ConstructionData.Offset.Y;
				Offset.Z = ConstructionData.Offset.Z;

				NewComp.SetRelativeLocation(Offset);
				NewComp.SetRelativeRotation(ConstructionData.RelativeRotation);
				NewComp.SetStaticMesh(ConstructionData.Mesh);
				Pieces.Add(NewComp);
			}

			// Create the floor drive shafts
			{
				const auto& ConstructionData = bIsLeft ? LeftShaftData : RightShaftData;
				auto NewComp = Cast<UClockWorkTowerMechanicalBridgeDriveShaft>(CreateComponent(UClockWorkTowerMechanicalBridgeDriveShaft::StaticClass(), FName(LeftName + "Shaft_" + i / 2)));
				NewComp.bIsLeft = bIsLeft;

				FVector Offset;
				Offset.X = ConstructionData.StartingDistanceOffset;
				Offset.X += i * ConstructionData.Offset.X;
				Offset.Y = ConstructionData.Offset.Y;
				Offset.Z = ConstructionData.Offset.Z;

				NewComp.SetRelativeLocation(Offset);
				NewComp.SetRelativeRotation(ConstructionData.RelativeRotation);
				NewComp.SetStaticMesh(ConstructionData.Mesh);
				NewComp.LocalQuatRotation = NewComp.RelativeRotation.Quaternion();
				Pieces[Shafts.Num()].Shaft = NewComp;
				Shafts.Add(NewComp);
			}
		}

		ActivationBounds.OnComponentBeginOverlap.Clear();
		ActivationBounds.OnComponentBeginOverlap.AddUFunction(this, n"EnterTrigger");

		ActivationBounds.OnComponentEndOverlap.Clear();
		ActivationBounds.OnComponentEndOverlap.AddUFunction(this, n"ExitTrigger");
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickEnabled(OverlappingPlayers.Num() > 0);

		// Create the needed Ak components, for int the middle of each piece row
		AkComponents.Reset(PieceAmount / 2);
		const float Offset = (RightData.Offset.X + LeftData.Offset.X) / 2;
		for(int i = 0; i < PieceAmount; i += 2)
		{
			FClockWorkTowerMechanicalBridgeAkData AkCompData;
			AkCompData.AkComponent = Cast<UHazeAkComponent>(CreateComponent(UHazeAkComponent::StaticClass(), FName("AkComponent_" + i / 2)));
			AkCompData.PitchAmount = PitchStartAmount + ((PitchIncreaseAmount) * (i / 2));
			FVector NewRelativeLocation;
			NewRelativeLocation.X = i * Offset;
			AkCompData.AkComponent.SetRelativeLocation(NewRelativeLocation);
			AkComponents.Add(AkCompData);
			AkCompData.AkComponent.SetRTPCValue("Rtpc_Clockwork_LowerTower_Platform_MechanicalBridge_Pitch", AkCompData.PitchAmount);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		bPiecesWantActorToBeActive = false;
		const int pCount = OverlappingPlayers.Num();
		const float Offset = (RightData.Offset.X + LeftData.Offset.X) / 2;
		const FVector Forward = GetActorForwardVector();
		const FVector StartLocation = GetActorLocation();

		if(OverlappingPlayers.Num() == 2)
		{
			// Get the players locations
			const FVector PlayerOneLocation = OverlappingPlayers[0].GetActorLocation();
			const FVector PlayerTwoLocation = OverlappingPlayers[1].GetActorLocation();

			// Update the pieces using the closest player location
			for(int i = 0; i < PieceAmount; i+=2)
			{
				// Get the position in the middle of the pieces
				FVector BridgeLocation = StartLocation;
				BridgeLocation += Forward * (i * Offset);
				
				const float DistOne = BridgeLocation.DistSquaredXY(PlayerOneLocation) - ActivationRangeRange.X;
				const float DistTwo = BridgeLocation.DistSquaredXY(PlayerTwoLocation) - ActivationRangeRange.X;
				float MinDist = FMath::Min(DistOne, DistTwo);
		
				// Get the alpha range
				const float DistanceAlpha = FMath::Clamp(MinDist / ActivationRangeRange.Y, 0.f, 1.f);
				UpdatePiece(Pieces[i], DeltaSeconds, DistanceAlpha);
				UpdatePiece(Pieces[i+1], DeltaSeconds, DistanceAlpha);
			}
		}
		else if(OverlappingPlayers.Num() == 1)
		{
			// Get the players locations
			const FVector PlayerOneLocation = OverlappingPlayers[0].GetActorLocation();
		
			// Update the pieces using the closest player location
			for(int i = 0; i < PieceAmount; i+=2)
			{
				// Get the position in the middle of the pieces
				FVector BridgeLocation = StartLocation;
				BridgeLocation += Forward * (i * Offset);
			
				float MinDist = BridgeLocation.DistSquaredXY(PlayerOneLocation) - ActivationRangeRange.X;
		
				// Get the alpha range
				const float DistanceAlpha = FMath::Clamp(MinDist / ActivationRangeRange.Y, 0.f, 1.f);
				UpdatePiece(Pieces[i], DeltaSeconds, DistanceAlpha);
				UpdatePiece(Pieces[i+1], DeltaSeconds, DistanceAlpha);
			}
		}
		else
		{
			// Update the pieces until everyone is inactive
			for(int i = 0; i < PieceAmount; i+=2)
			{
				UpdatePiece(Pieces[i], DeltaSeconds, 1.f);
				UpdatePiece(Pieces[i+1], DeltaSeconds, 1.f);
			}
		}

		// Update audio
		const bool bActorWillDisable = OverlappingPlayers.Num() == 0 && !bPiecesWantActorToBeActive;
		for(int i = 0; i < AkComponents.Num(); ++i)
		{
			if(bActorWillDisable)
				StopAudio(AkComponents[i]);
			else
				UpdateAudio(DeltaSeconds, AkComponents[i], Pieces[i * 2]);
		}

		if(bActorWillDisable)
			SetActorTickEnabled(false);
	}

	void UpdatePiece(UClockWorkTowerMechanicalBridgePiece Piece, float DeltaTime, float DistanceAlpha)
	{
		const float CurrentRotationPitch = Piece.RelativeRotation.Pitch;
		const FRotator IdleRotation = Piece.bIsLeft ? LeftData.RelativeRotation : RightData.RelativeRotation;
		FRotator TargetRotation = IdleRotation;
		TargetRotation.Pitch = FMath::Lerp(0.f, IdleRotation.Pitch, DistanceAlpha);
		TargetRotation.Pitch = FMath::FInterpTo(Piece.RelativeRotation.Pitch, TargetRotation.Pitch, DeltaTime, 5);
		Piece.bIsMoving = FMath::Abs(CurrentRotationPitch - TargetRotation.Pitch) > 0.1f;
		Piece.bPlayMovingSound = FMath::Abs(CurrentRotationPitch - TargetRotation.Pitch) > 0.2f;
		
		if(Piece.bIsMoving)
		{
			Piece.SetRelativeRotation(TargetRotation);

			const float SpeedMultiplier = 3;
			FQuat DeltaRot;
			if(Piece.Shaft.bIsLeft)
				DeltaRot = FRotator((TargetRotation.Pitch - CurrentRotationPitch) * SpeedMultiplier, 0.f, 0.f).Quaternion();
			else
				DeltaRot = FRotator((CurrentRotationPitch - TargetRotation.Pitch) * SpeedMultiplier, 0.f, 0.f).Quaternion();
			Piece.Shaft.LocalQuatRotation *= DeltaRot;
			Piece.Shaft.LocalQuatRotation.Normalize();
			Piece.Shaft.SetRelativeRotation(Piece.Shaft.LocalQuatRotation);
		}

		if(DistanceAlpha < 1 || Piece.bIsMoving)
			bPiecesWantActorToBeActive = true;
	}

	void UpdateAudio(float DeltaTime, FClockWorkTowerMechanicalBridgeAkData& AkCompData, UClockWorkTowerMechanicalBridgePiece MasterPiece)
	{
		if(MasterPiece.bPlayMovingSound)
			AkCompData.AudioVelocity = FMath::FInterpConstantTo(AkCompData.AudioVelocity, 1, DeltaTime, 2);
		else
			AkCompData.AudioVelocity = FMath::FInterpConstantTo(AkCompData.AudioVelocity, 0, DeltaTime, 2);	

		AkCompData.AkComponent.SetRTPCValue("Rtpc_Clockwork_LowerTower_Platform_MechanicalBridge_Velocity", AkCompData.AudioVelocity);
		
		// 0 - 90
		float AudioProgress = FMath::Abs(MasterPiece.RelativeRotation.Pitch);
		AkCompData.AkComponent.SetRTPCValue("Rtpc_Clockwork_LowerTower_Platform_MechanicalBridge_Progress", AudioProgress);
		
		// Update Top sound
		const bool bShouldPlayTopSound = AudioProgress <= 1;
		if(bShouldPlayTopSound && !AkCompData.bHasPlayedTopSound)
		{
			AkCompData.bHasPlayedTopSound = true;
			AkCompData.AkComponent.HazePostEvent(ReachedTopSound);
		}
		else if(!bShouldPlayTopSound && AkCompData.bHasPlayedTopSound)
		{
			AkCompData.bHasPlayedTopSound = false;
		}

		// Check if we should play audio
		if(MasterPiece.bPlayMovingSound)
		{
			if(!AkCompData.bHasStartedPlayingSound)
			{
				AkCompData.bHasStartedPlayingSound = true;
				AkCompData.AkComponent.HazePostEvent(MovingSound);
			}
		}
		else
		{
			StopAudio(AkCompData);
		}
	}

	void StopAudio(FClockWorkTowerMechanicalBridgeAkData& AkCompData)
	{
		if(!AkCompData.bHasStartedPlayingSound)
			return;
		
		AkCompData.bHasStartedPlayingSound = false;
		AkCompData.AkComponent.HazePostEvent(StopSound);
	}

	UFUNCTION(NotBlueprintCallable)
	private void EnterTrigger(
		UPrimitiveComponent OverlappedComponent,
		AActor OtherActor,
		UPrimitiveComponent OtherComponent, 
		int OtherBodyIndex,
		bool bFromSweep, 
		FHitResult& Hit)
	{
		auto OverlappingPlayer = Cast<AHazePlayerCharacter>(OtherActor);
		if(OverlappingPlayer != nullptr)
		{
			OverlappingPlayers.Add(OverlappingPlayer);
		}

		if(OverlappingPlayers.Num() == 1)
			SetActorTickEnabled(true);
	}

	
	UFUNCTION(NotBlueprintCallable)
    void ExitTrigger(
		UPrimitiveComponent 
		OverlappedComponent, 
		AActor OtherActor, 
		UPrimitiveComponent 
		OtherComponent, 
		int OtherBodyIndex)
	{
		auto OverlappingPlayer = Cast<AHazePlayerCharacter>(OtherActor);
		if(OverlappingPlayer != nullptr)
		{
			OverlappingPlayers.RemoveSwap(OverlappingPlayer);
		}
	}
}

class UClockWorkTowerMechanicalBridgePiece : UStaticMeshComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;
	default SetCollisionProfileName(n"NoCollision");
	default SetCastShadow(false);

	UPROPERTY(EditConst)
	UClockWorkTowerMechanicalBridgeDriveShaft Shaft;

	UPROPERTY(EditConst)
	bool bIsLeft = false;
	
	UPROPERTY(EditConst)
	bool bIsMoving = false;

	bool bPlayMovingSound = false;
}

class UClockWorkTowerMechanicalBridgeDriveShaft : UStaticMeshComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;
	default SetCollisionProfileName(n"NoCollision");
	default SetCastShadow(false);

	UPROPERTY(EditConst)
	bool bIsLeft = false;

	UPROPERTY(EditConst)
	FQuat LocalQuatRotation;
}
