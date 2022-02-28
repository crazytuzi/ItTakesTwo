import Cake.LevelSpecific.Music.Cymbal.CymbalReceptacle;
import Vino.PlayerHealth.PlayerHealthStatics;

enum ESquaresToCover
{  
    HalfSquare,
	OneSquare,
	FourSquares,
	NineSquares
};

class AStudioABlockingPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USceneComponent LaserLocation;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USceneComponent PillarMeshRoot;

	UPROPERTY(DefaultComponent, Attach = PillarMeshRoot)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USceneComponent LidMeshRoot;

	UPROPERTY(DefaultComponent, Attach = LidMeshRoot)
	UStaticMeshComponent LidMesh;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UBoxComponent KillCollision;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UNiagaraComponent SpeakerFX;
	default SpeakerFX.bAutoActivate = false;

	UPROPERTY()
	float TargetHeight = 1500.f;

	UPROPERTY(Meta = (MakeEditWidget, EditCondition = "bCanBeMovedTwice"))
	float SecondTargetHeight = 1500.f;

	UPROPERTY()
	bool bShowTargetHeight = false;

	UPROPERTY(Meta = (MakeEditWidget, EditCondition = "bCanBeMovedTwice"))
	bool bShowSecondTargetHeight = false;

	UPROPERTY()
	bool bStartWithLidRotated = false;

	UPROPERTY()
	bool bShouldNotFlipLid = false;

	UPROPERTY()
	bool bCanBeMovedTwice = false;

	UPROPERTY()
	bool bFlipLidFirstTime = false;

	UPROPERTY()
	bool bShouldHaveFX = false;

	UPROPERTY()
	bool bShouldHaveKillCollision = false;

	UPROPERTY()
	bool bDebugMode = false;

	UPROPERTY()
	AActor ConnectedLaser;

	UPROPERTY()
	ESquaresToCover SquaresToCover;
	default SquaresToCover = ESquaresToCover::OneSquare;

	bool bShouldTickMoveMovePillarTimer = false;

	bool bStartMove = false;

	UPROPERTY()
	bool bHasMovedFirstTime = false;

	UPROPERTY()
	bool bMovingSecondTime = false;

	float MoveMovePillarTimer = 0.f;

	bool bShouldTickMovePillarTimer = false;
	float MovePillarTimer = 2.f;
	
	UPROPERTY()
	FVector StartingLoc;
	
	UPROPERTY()
	FVector TargetLoc;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (ConnectedLaser != nullptr)
			ConnectedLaser.AttachToComponent(LaserLocation, n"", EAttachmentRule::SnapToTarget);
		
		MeshRoot.SetRelativeLocation(FVector(MeshRoot.RelativeLocation.X, MeshRoot.RelativeLocation.Y, 0.f));

		if(bShouldHaveKillCollision)
		{
			MovePillarTimer = 0.f;
			KillCollision.OnComponentBeginOverlap.AddUFunction(this, n"KillCollisionOverlap");
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bShouldTickMoveMovePillarTimer)
		{
			MoveMovePillarTimer -= DeltaTime;
			if (MoveMovePillarTimer <= 0.f)
			{
				bShouldTickMoveMovePillarTimer = false;
				MoveLid();
			}
		}

		if (bShouldTickMovePillarTimer)
		{
			MovePillarTimer -= DeltaTime;
			if (MovePillarTimer <= 0.f)
			{
				bShouldTickMovePillarTimer = false;
				MovePillar();
			}
		}
	}

	UFUNCTION(CallInEditor)
	void SetRandomTargetHeightOffset()
	{
		TargetHeight += FMath::RandRange(-80.f, 80.f);
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		bStartWithLidRotated ? LidMeshRoot.SetRelativeRotation(FRotator(0.f, 0.f, 180.f)) : LidMeshRoot.SetRelativeRotation(FRotator::ZeroRotator);

		if (!bCanBeMovedTwice)
			KillCollision.SetVisibility(false);
		else	
			KillCollision.SetVisibility(true);


		switch (SquaresToCover)
		{
			case ESquaresToCover::OneSquare:
			MeshRoot.SetRelativeScale3D(FVector(1.f, 1.f, 1.f));
			break;

			case ESquaresToCover::FourSquares:
			MeshRoot.SetRelativeScale3D(FVector(2.f, 2.f, 2.f));
			break;

			case ESquaresToCover::NineSquares:
			MeshRoot.SetRelativeScale3D(FVector(3.f, 3.f, 3.f));
			break;

			case ESquaresToCover::HalfSquare:
			MeshRoot.SetRelativeScale3D(FVector(.5f, 1.f, 1.f));
			break;
		}

		if (bShowTargetHeight)
			MeshRoot.SetRelativeLocation(FVector(MeshRoot.RelativeLocation.X, MeshRoot.RelativeLocation.Y, TargetHeight));
		else if (bShowSecondTargetHeight)
			MeshRoot.SetRelativeLocation(FVector(MeshRoot.RelativeLocation.X, MeshRoot.RelativeLocation.Y, TargetHeight + SecondTargetHeight));			
		else
			MeshRoot.SetRelativeLocation(FVector(MeshRoot.RelativeLocation.X, MeshRoot.RelativeLocation.Y, 0.f));
	}

	UFUNCTION()
	void StartMovingPillar(float NewMoveMovePillarTimer)
	{
		if (bHasMovedFirstTime && !bCanBeMovedTwice)
			return;

		if (!bHasMovedFirstTime)
		{
			StartingLoc = PillarMeshRoot.RelativeLocation;
			TargetLoc = StartingLoc + FVector(0.f, 0.f, TargetHeight);
			
			if (bCanBeMovedTwice && bShouldHaveFX)
			{
				if (bDebugMode)
					Print("NEINNEINNEIN", 2.f);
				
				SpeakerFX.Activate();
			}
		} else
		{
			if (bDebugMode)
				Print("YEEYYEEY", 2.f);
			bMovingSecondTime = true;
			StartingLoc = TargetLoc;
			TargetLoc = StartingLoc + FVector(0.f, 0.f, SecondTargetHeight);
			
			if (bShouldHaveFX)
				SpeakerFX.Deactivate();
		}

		MoveMovePillarTimer = NewMoveMovePillarTimer;
		bShouldTickMoveMovePillarTimer = true;
		bHasMovedFirstTime = true;
	}

	UFUNCTION(BlueprintEvent)
	void MoveLid()
	{
		bShouldTickMovePillarTimer = true;
		// This is done in BP!
	}

	UFUNCTION(BlueprintEvent)
	void MovePillar()
	{
		// This is done in BP!
	}

	UFUNCTION()
	void KillCollisionOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex, 
    bool bFromSweep, FHitResult& Hit)
	{
		if (bMovingSecondTime)
			return;

		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player != nullptr)
		{
			KillPlayer(Player);
		}
	}
}