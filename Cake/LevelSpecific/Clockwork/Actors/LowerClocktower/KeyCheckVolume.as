import Vino.Interactions.InteractionComponent;
import Cake.LevelSpecific.Clockwork.Actors.LowerClocktower.ClockworkKey;

event void FKeyCheckVolumeSignature();

UCLASS(Abstract, HideCategories = "Cooking Replication Input Actor Capability LOD")
class AKeyCheckVolume : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UInteractionComponent InteractionComp;
	default InteractionComp.ActionShapeTransform.Scale3D = FVector(1.5f, 1.5f, 1.5f);
	default InteractionComp.FocusShapeTransform.Location = FVector(0.f, 0.f, 100.f);
	default InteractionComp.MovementSettings.InitializeSmoothTeleport();

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent KeyMeshRoot;
	default KeyMeshRoot.RelativeLocation = FVector(90.f, 0.f, 160.f);
	
	UPROPERTY(DefaultComponent, Attach = KeyMeshRoot)
	UStaticMeshComponent KeyMesh;
	default KeyMesh.bHiddenInGame = true;
	default KeyMesh.CollisionEnabled = ECollisionEnabled::NoCollision;

	UPROPERTY(DefaultComponent, Attach = InteractionComp)
	USkeletalMeshComponent PreviewMesh;
	default PreviewMesh.bIsEditorOnly = true;
	default PreviewMesh.bHiddenInGame = true;
	default PreviewMesh.CollisionEnabled = ECollisionEnabled::NoCollision;

	UPROPERTY()
	float KeyRotationDuration;
	default KeyRotationDuration = 3.f;

	float CurrentKeyRotationDuration;

	UPROPERTY()
	float KeyRotationSpeedMax;
	default KeyRotationSpeedMax = 800.f;

	UPROPERTY()
	UAnimSequence CodyPlaceKeyAnim;

	UPROPERTY()
	UAnimSequence MayPlaceKeyAnim;

	bool bKeyWasPlaced;
	bool bDoorWasOpened = false;

	float KeyWasPlacedTimerMax;
	default KeyWasPlacedTimerMax = .5f;

	float KeyWasPlacedTimer;


	UPROPERTY()
	FKeyCheckVolumeSignature DoorUnlockedEvent;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InteractionComp.OnActivated.AddUFunction(this, n"InteractionCompActivated");
		KeyRotationDuration /= 2.f;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{		
		if (bDoorWasOpened)
			return;

		if (bKeyWasPlaced)
		{
			KeyWasPlacedTimer += DeltaTime;
			if (KeyWasPlacedTimer >= KeyWasPlacedTimerMax)
			{
				RotateKey(DeltaTime);
			}
		}
	}

	UFUNCTION()
	void InteractionCompActivated(UInteractionComponent Comp, AHazePlayerCharacter Player)
	{
		TArray<AActor> ActorArray;
		Player.GetAttachedActors(ActorArray);

		for (AActor Actor : ActorArray)
		{
			AClockworkKey Key = Cast<AClockworkKey>(Actor);
			if (Key != nullptr)
			{
				UAnimSequence AnimToPlay = Player == Game::GetCody() ? CodyPlaceKeyAnim : MayPlaceKeyAnim;
				Player.PlayEventAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(), AnimToPlay);
				Key.RemoveOutline();
				Key.DestroyActor();
				PlaceKey();
				InteractionComp.Disable(n"KeyWasPutInDoor");
			}
		}
	}

	void PlaceKey()
	{
		KeyMesh.SetHiddenInGame(false);
		bKeyWasPlaced = true;
	}

	void RotateKey(float DeltaTime)
	{
		if (CurrentKeyRotationDuration < 2.f)
		{
			CurrentKeyRotationDuration += DeltaTime / KeyRotationDuration;			
			KeyMeshRoot.AddRelativeRotation(FRotator(0.f, 0.f, FMath::SinusoidalInOut(0.f, KeyRotationSpeedMax, CurrentKeyRotationDuration)) * DeltaTime); 
		} else 
		{
			DoorWasUnlocked();
		}	
	}

	void DoorWasUnlocked()
	{
		bDoorWasOpened = true;
		DoorUnlockedEvent.Broadcast();
	}
}