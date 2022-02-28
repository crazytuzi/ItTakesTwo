import Vino.Interactions.InteractionComponent;
enum EMemoryFruit
{  
    Banana,
	Cherry,
	Eggplant,
	Orange,
	Pear,
	Strawberry
};

event void EMemoryCardSignature(EMemoryFruit Animal, AHomeworkMemoryCard MemoryCard);

UCLASS(Abstract, HideCategories = "Cooking Replication Input Actor Capability LOD")
class AHomeworkMemoryCard : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	
	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent CardMeshRoot;
	default CardMeshRoot.RelativeRotation = FRotator(0.f, 0.f, -180.f);

	UPROPERTY(DefaultComponent, Attach = CardMeshRoot)
	UStaticMeshComponent CardMesh;
	default CardMesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(DefaultComponent, Attach = CardMeshRoot)
	UInteractionComponent InteractionPoint;
	default InteractionPoint.RelativeLocation = FVector(0.f, 0.f, 0.f);
	default InteractionPoint.ActionShapeTransform.Scale3D = FVector (1.f, 1.f, 1.f);
	default InteractionPoint.ActionShapeTransform.Location = FVector(0.f, 0.f, 0.f);
	default InteractionPoint.ActivationSettings.NetworkMode = EHazeTriggerNetworkMode::AlwaysHost;

	FRotator InitialRotation;
	FRotator TargetRotation;

	FVector StartingHeight;
	FVector TargetHeight;

	FVector InitialWorldLocation;
	FVector StartLocBeforeShuffle;
	FVector TargetLocBeforeShuffle;
	FVector StartLocAfterShuffle;
	FVector TargetLocAfterShuffle;

	float MoveCardDelay;

	bool bHasShuffled;

	bool bCardIsFlipped;

	UPROPERTY()
	FHazeTimeLike FlipCardTimeline;
	default FlipCardTimeline.Duration = 0.5f;

	UPROPERTY()
	FHazeTimeLike LiftCardTimeline;
	default LiftCardTimeline.Duration = 0.5f;

	UPROPERTY()
	FHazeTimeLike MoveCardTimeline;
	default MoveCardTimeline.Duration = 0.4f;

	UPROPERTY()
	EMemoryCardSignature CardFlippedEvent;

	UPROPERTY()
	UMaterialInterface BananaMat;

	UPROPERTY()
	UMaterialInterface CherryMat;

	UPROPERTY()
	UMaterialInterface EggplantMat;

	UPROPERTY()
	UMaterialInterface OrangeMat;

	UPROPERTY()
	UMaterialInterface PearMat;

	UPROPERTY()
	UMaterialInterface StrawberryMat;
	UPROPERTY()
	EMemoryFruit MemoryFruit;

	UPROPERTY()
	float InitialFlipDelay;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InteractionPoint.OnActivated.AddUFunction(this, n"InteractActivated");
		
		FlipCardTimeline.BindUpdate(this, n"FlipCardTimelineUpdate");
		LiftCardTimeline.BindUpdate(this, n"LiftCardTimelineUpdate");
		MoveCardTimeline.BindUpdate(this, n"MoveCardTimelineUpdate");

		InitialRotation = CardMeshRoot.RelativeRotation;
		TargetRotation = FRotator(CardMeshRoot.RelativeRotation + FRotator(0.f, 0.f, 180.f));

		StartingHeight = CardMeshRoot.RelativeLocation;
		TargetHeight = FVector(CardMeshRoot.RelativeLocation + FVector(0.f, 0.f, 150.f));

		InitialWorldLocation = CardMeshRoot.GetWorldLocation();

		CardMeshRoot.SetRelativeRotation(TargetRotation);
		SetInteractionPointEnabled(false);
	}

	UFUNCTION()
	void InteractActivated(UInteractionComponent Comp, AHazePlayerCharacter Player)
	{		
			LiftCardTimeline.PlayFromStart();
			FlipCardTimeline.PlayFromStart();
			bCardIsFlipped = true;

			SetInteractionPointEnabled(false);
			CardFlippedEvent.Broadcast(MemoryFruit, this);
			AudioFlipCard();
	}

	UFUNCTION()
	void InitialFlip()
	{
		System::SetTimer(this, n"FlipBackCard", InitialFlipDelay, false);
	}

	UFUNCTION()
	void MoveCardsToMiddleTimer()
	{
		System::SetTimer(this, n"MoveCards", InitialFlipDelay, false);
	}

	UFUNCTION()
	void MoveCardsAfterShuffleTimer()
	{
		System::SetTimer(this, n"MoveCards", MoveCardDelay, false);
	}

	UFUNCTION()
	void MoveCards()
	{
		MoveCardTimeline.PlayFromStart();
		AudioMoveCard();
	}

	UFUNCTION()
	void FlipBackCard()
	{
		LiftCardTimeline.ReverseFromEnd();
		FlipCardTimeline.ReverseFromEnd();
		AudioUnFlipCard();
		bCardIsFlipped = false;
	}

	UFUNCTION()
	void SetInteractionPointEnabled(bool bEnabled)
	{
		if (bEnabled)
			InteractionPoint.Enable(n"");
		else
			InteractionPoint.Disable(n"");
	}

	UFUNCTION()
	void FlipCardTimelineUpdate(float CurrentValue)
	{
		CardMeshRoot.SetRelativeRotation(QuatLerp(InitialRotation, TargetRotation, CurrentValue));
	}

	UFUNCTION()
	void LiftCardTimelineUpdate(float CurrentValue)
	{
		CardMeshRoot.SetRelativeLocation(FMath::VLerp(StartingHeight, TargetHeight, FVector(CurrentValue, CurrentValue, CurrentValue)));
	}

	UFUNCTION()
	void MoveCardTimelineUpdate(float CurrentValue)
	{
		if (bHasShuffled)
			CardMeshRoot.SetWorldLocation(FMath::VLerp(StartLocAfterShuffle, TargetLocAfterShuffle, FVector(CurrentValue, CurrentValue, CurrentValue)));
		else
			CardMeshRoot.SetWorldLocation(FMath::VLerp(StartLocBeforeShuffle, TargetLocBeforeShuffle, FVector(CurrentValue, CurrentValue, CurrentValue)));
	}

	UFUNCTION()
	void SetFlipTargets()
	{
		InitialRotation = CardMeshRoot.RelativeRotation;
		TargetRotation = FRotator(CardMeshRoot.RelativeRotation + FRotator(0.f, 0.f, 180.f));

		StartingHeight = CardMeshRoot.RelativeLocation;
		TargetHeight = FVector(CardMeshRoot.RelativeLocation + FVector(0.f, 0.f, 150.f));
	}

	UFUNCTION()
	void SetAnimal(EMemoryFruit NewFruit)
	{
		UStaticMesh MeshToSet;
		MemoryFruit = NewFruit;

		switch (NewFruit)
        {
        case EMemoryFruit::Banana:
		CardMesh.SetMaterial(0, BananaMat);
        break;

		case EMemoryFruit::Cherry:
		CardMesh.SetMaterial(0, CherryMat);
        break;

		case EMemoryFruit::Eggplant:
		CardMesh.SetMaterial(0, EggplantMat);
        break;

		case EMemoryFruit::Orange:
		CardMesh.SetMaterial(0, OrangeMat);
        break;

		case EMemoryFruit::Pear:
		CardMesh.SetMaterial(0, PearMat);
        break;

		case EMemoryFruit::Strawberry:
		CardMesh.SetMaterial(0, StrawberryMat);
        break;
        }
	}

	FRotator QuatLerp(FRotator A, FRotator B, float Alpha)
    {
		FQuat AQuat(A);
		FQuat BQuat(B);
		FQuat Result = FQuat::Slerp(AQuat, BQuat, Alpha);
		Result.Normalize();
		return Result.Rotator();
    }

	UFUNCTION(BlueprintEvent, BlueprintCallable)
	void AudioFlipCard()
	{

	}

	UFUNCTION(BlueprintEvent, BlueprintCallable)
	void AudioUnFlipCard()
	{

	}

	UFUNCTION(BlueprintEvent, BlueprintCallable)
	void AudioMoveCard()
	{

	}
}