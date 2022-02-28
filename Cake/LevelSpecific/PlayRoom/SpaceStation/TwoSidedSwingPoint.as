import Vino.Movement.Swinging.SwingComponent;

event void FTwoSidedSwingPointHidden();
event void BothPlayersOnSwingPoint();

UCLASS(Abstract)
class ATwoSidedSwingPoint : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent BodyRoot;

	UPROPERTY(DefaultComponent, Attach = BodyRoot)
	UStaticMeshComponent BodyMesh;

	UPROPERTY(DefaultComponent, Attach = BodyRoot)
	USceneComponent TopSwingRoot;

	UPROPERTY(DefaultComponent, Attach = TopSwingRoot)
	USceneComponent TopSwingLeftRoot;

	UPROPERTY(DefaultComponent, Attach = TopSwingRoot)
	USceneComponent TopSwingRightRoot;

	UPROPERTY(DefaultComponent, Attach = TopSwingLeftRoot)
	UStaticMeshComponent TopSwingLeftMesh;

	UPROPERTY(DefaultComponent, Attach = TopSwingRightRoot)
	UStaticMeshComponent TopSwingRightMesh;

	UPROPERTY(DefaultComponent, Attach = TopSwingRoot)
	USwingPointComponent TopSwingComp;

	UPROPERTY(DefaultComponent, Attach = BodyRoot)
	USceneComponent BottomSwingRoot;

	UPROPERTY(DefaultComponent, Attach = BottomSwingRoot)
	USceneComponent BottomSwingLeftRoot;

	UPROPERTY(DefaultComponent, Attach = BottomSwingRoot)
	USceneComponent BottomSwingRightRoot;

	UPROPERTY(DefaultComponent, Attach = BottomSwingLeftRoot)
	UStaticMeshComponent BottomSwingLeftMesh;

	UPROPERTY(DefaultComponent, Attach = BottomSwingRightRoot)
	UStaticMeshComponent BottomSwingRightMesh;

	UPROPERTY(DefaultComponent, Attach = BottomSwingRoot)
	USwingPointComponent BottomSwingComp;

	UPROPERTY(EditDefaultsOnly)
	UMaterialInterface HappyFaceMaterial;

	UPROPERTY(EditDefaultsOnly)
	UMaterialInterface AngryFaceMaterial;

	UPROPERTY(EditDefaultsOnly)
	UMaterialInterface TiltedFaceMaterial;

	UPROPERTY()
	FTwoSidedSwingPointHidden OnSwingPointHidden;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopSideScrollerWhooshAudioEvent;

	UPROPERTY()
	BothPlayersOnSwingPoint AudioBothPlayersOnSwingPoint;

	UPROPERTY()
	bool bTopIsMainSwingPoint = false;

	bool bExposing = false;
	bool bPermanentlyExposed = false;

	USceneComponent NonMainSwingRoot;
	USwingPointComponent NonMainSwingComp;

	int FaceMaterialIndex = 3;

	int ActiveSwingers = 0;

	FHazeConstrainedPhysicsValue PhysValue;
	default PhysValue.LowerBound = -50.f;
	default PhysValue.UpperBound = 50.f;
	default PhysValue.LowerBounciness = 0.2f;
	default PhysValue.UpperBounciness = 0.2f;
	default PhysValue.Friction = 2.1f;

	UPROPERTY(NotEditable)
	float FullyExposedOffset = 70.f;
	UPROPERTY(NotEditable)
	float FullyHiddenOffset = -35.f;

	default PrimaryActorTick.bStartWithTickEnabled = false;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (bTopIsMainSwingPoint)
		{
			TopSwingLeftMesh.SetRelativeLocation(FVector(0.f, 0.f, FullyExposedOffset));
			TopSwingRightMesh.SetRelativeLocation(FVector(0.f, 0.f, FullyExposedOffset));
			BottomSwingLeftMesh.SetRelativeLocation(FVector(0.f, 0.f, FullyHiddenOffset));
			BottomSwingRightMesh.SetRelativeLocation(FVector(0.f, 0.f, FullyHiddenOffset));

			TopSwingLeftRoot.SetRelativeRotation(FRotator(0.f, 0.f, 0.f));
			TopSwingRightRoot.SetRelativeRotation(FRotator(0.f, 0.f, 0.f));

			BottomSwingLeftRoot.SetRelativeRotation(FRotator(0.f, 0.f, 90.f));
			BottomSwingRightRoot.SetRelativeRotation(FRotator(0.f, 0.f, -90.f));

		}
		else
		{
			BottomSwingLeftMesh.SetRelativeLocation(FVector(0.f, 0.f, FullyExposedOffset));
			BottomSwingRightMesh.SetRelativeLocation(FVector(0.f, 0.f, FullyExposedOffset));
			TopSwingLeftMesh.SetRelativeLocation(FVector(0.f, 0.f, FullyHiddenOffset));
			TopSwingRightMesh.SetRelativeLocation(FVector(0.f, 0.f, FullyHiddenOffset));

			TopSwingLeftRoot.SetRelativeRotation(FRotator(0.f, 0.f, -90.f));
			TopSwingRightRoot.SetRelativeRotation(FRotator(0.f, 0.f, 90.f));

			BottomSwingLeftRoot.SetRelativeRotation(FRotator(0.f, 0.f, 0.f));
			BottomSwingRightRoot.SetRelativeRotation(FRotator(0.f, 0.f, 0.f));
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TopSwingComp.OnSwingPointAttached.AddUFunction(this, n"AttachedToTop");
		TopSwingComp.OnSwingPointDetached.AddUFunction(this, n"DetachedFromTop");

		BottomSwingComp.OnSwingPointAttached.AddUFunction(this, n"AttachedToBottom");
		BottomSwingComp.OnSwingPointDetached.AddUFunction(this, n"DetachedFromBottom");

		NonMainSwingRoot = bTopIsMainSwingPoint ? BottomSwingRoot : TopSwingRoot;
		NonMainSwingComp = bTopIsMainSwingPoint ? BottomSwingComp : TopSwingComp;

		if (bTopIsMainSwingPoint)
		{
			TopSwingComp.SetSwingPointEnabled(true);
			BottomSwingComp.SetSwingPointEnabled(false);
		}
		else
		{
			TopSwingComp.SetSwingPointEnabled(false);
			BottomSwingComp.SetSwingPointEnabled(true);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		PhysValue.SpringTowards(0.f, 120.f);
		PhysValue.Update(DeltaTime);

		BodyRoot.SetRelativeLocation(FVector(0.f, 0.f, PhysValue.Value));

		if (FMath::Abs(PhysValue.Value) <= SMALL_NUMBER && FMath::Abs(PhysValue.Velocity) <= KINDA_SMALL_NUMBER)
			SetActorTickEnabled(false);
	}

	UFUNCTION()
	void PermanentlyExpose()
	{
		if (bPermanentlyExposed)
			return;

		ExposeSwingPoint();

		bPermanentlyExposed = true;

		TopSwingComp.SetSwingPointEnabled(true);
		BottomSwingComp.SetSwingPointEnabled(true);
	}

	UFUNCTION(NotBlueprintCallable)
	void AttachedToTop(AHazePlayerCharacter Player)
	{
		PhysValue.AddImpulse(200.f);
		SetActorTickEnabled(true);
		ActiveSwingers++;
		UpdateFace();
		if (bTopIsMainSwingPoint)
			ExposeSwingPoint();
	}

	UFUNCTION(NotBlueprintCallable)
	void DetachedFromTop(AHazePlayerCharacter Player)
	{
		PhysValue.AddImpulse(-200.f);
		SetActorTickEnabled(true);
		ActiveSwingers--;
		UpdateFace();
		if (bTopIsMainSwingPoint)
			HideSwingPoint();
	}

	UFUNCTION(NotBlueprintCallable)
	void AttachedToBottom(AHazePlayerCharacter Player)
	{
		PhysValue.AddImpulse(-200.f);
		SetActorTickEnabled(true);
		ActiveSwingers++;
		UpdateFace();
		if (!bTopIsMainSwingPoint)
			ExposeSwingPoint();
	}

	UFUNCTION(NotBlueprintCallable)
	void DetachedFromBottom(AHazePlayerCharacter Player)
	{
		PhysValue.AddImpulse(200.f);
		SetActorTickEnabled(true);
		ActiveSwingers--;
		UpdateFace();
		if (!bTopIsMainSwingPoint)
			HideSwingPoint();
	}

	void ExposeSwingPoint()
	{
		if (bPermanentlyExposed)
			return;

		bExposing = true;
		BP_ExposeSwingPoint();
	}

	void UpdateFace()
	{
		if (ActiveSwingers == 0)
		{
			BodyMesh.SetMaterial(FaceMaterialIndex, HappyFaceMaterial);
			if(StopSideScrollerWhooshAudioEvent != nullptr)
				UHazeAkComponent::HazePostEventFireForget(StopSideScrollerWhooshAudioEvent, FTransform()); 
		}
			
		else if (ActiveSwingers == 1)
		{
			BodyMesh.SetMaterial(FaceMaterialIndex, AngryFaceMaterial);
			if(StopSideScrollerWhooshAudioEvent != nullptr)
				UHazeAkComponent::HazePostEventFireForget(StopSideScrollerWhooshAudioEvent, FTransform()); 
		}
			
		else if (ActiveSwingers == 2)
		{
			BodyMesh.SetMaterial(FaceMaterialIndex, TiltedFaceMaterial);
			AudioBothPlayersOnSwingPoint.Broadcast();		
		}
			
	}

	void HideSwingPoint()
	{
		if (bPermanentlyExposed)
			return;

		bExposing = false;
		BP_HideSwingPoint();
		NonMainSwingComp.SetSwingPointEnabled(false);
		OnSwingPointHidden.Broadcast();
	}

	UFUNCTION(BlueprintEvent)
	void BP_ExposeSwingPoint() {}

	UFUNCTION(BlueprintEvent)
	void BP_HideSwingPoint() {}

	UFUNCTION()
	void FullyExposed()
	{
		if (bPermanentlyExposed)
			return;

		if (bExposing)
		{
			NonMainSwingComp.SetSwingPointEnabled(true);
		}
	}
}