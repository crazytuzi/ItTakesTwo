import Vino.Movement.Components.GroundPound.GroundpoundedCallbackComponent;
import Vino.Movement.Components.ImpactCallback.ActorImpactedCallbackGlobalBindFunctions;

class AGroundPoundableClockweight : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComponent)
	USceneComponent PhysicsRoot;

	UPROPERTY(DefaultComponent, Attach = PhysicsRoot)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	USceneComponent GroundPoundIconLocation;

	UPROPERTY(DefaultComponent)
	UBoxComponent WidgetArea;

	UPROPERTY()
	TSubclassOf<UHazeUserWidget> GroundPoundWidget;

	UPROPERTY(Transient)
	UHazeUserWidget GPWidget;

	FHazeConstrainedPhysicsValue PhysValue;
	default PhysValue.LowerBound = -75.f;
	default PhysValue.UpperBound = 5.f;
	default PhysValue.LowerBounciness = 0.35f;
	default PhysValue.UpperBounciness = 0.15f;
	default PhysValue.Friction = 2.f;

	bool bIsInsideWidgetArea = false;
	bool bWidgetIsVisible = false;
	bool bAlreadyGroundPounded = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		WidgetArea.OnComponentBeginOverlap.AddUFunction(this, n"TriggeredOnBeginOverlap");
        WidgetArea.OnComponentEndOverlap.AddUFunction(this, n"TriggeredOnEndOverlap");
		FActorGroundPoundedDelegate OnGroundPound;
		OnGroundPound.BindUFunction(this, n"OnActorGroundPounded");
		BindOnActorGroundPounded(this, OnGroundPound);

		FActorImpactedByPlayerDelegate ImpactDelegate;
		ImpactDelegate.BindUFunction(this, n"LandOnPlatform");
		BindOnDownImpactedByPlayer(this, ImpactDelegate);

		FActorNoLongerImpactingByPlayerDelegate NoImpactDelegate;
		NoImpactDelegate.BindUFunction(this, n"LeavePlatform");
		BindOnDownImpactEndedByPlayer(this, NoImpactDelegate);
	}

	UFUNCTION(NotBlueprintCallable)
	void LandOnPlatform(AHazePlayerCharacter Player, FHitResult Hit)
	{
		if(!bAlreadyGroundPounded)
			PhysValue.AddImpulse(-100.f);
	}

	UFUNCTION(NotBlueprintCallable)
	void LeavePlatform(AHazePlayerCharacter Player)
	{
		if(!bAlreadyGroundPounded)
			PhysValue.AddImpulse(-25.f);
	}

	UFUNCTION()
    void TriggeredOnBeginOverlap(
        UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex,
        bool bFromSweep, FHitResult& Hit)
    {
		if(OtherActor == Game::GetMay())
		{
			bIsInsideWidgetArea = true;
			ShowWidget();
		}
    }

    UFUNCTION()
    void TriggeredOnEndOverlap(
        UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex)
    {
		if(OtherActor == Game::GetMay())
		{
			bIsInsideWidgetArea = false;
			HideWidget();
		}
    }

	void ShowWidget()
	{
		if(bAlreadyGroundPounded)
			return;

		if(bWidgetIsVisible)
			return;

		if(!bIsInsideWidgetArea)
			return;

		if(GPWidget == nullptr)
			GPWidget = Game::GetMay().AddWidget(GroundPoundWidget);
		else
			Game::GetMay().AddExistingWidget(GPWidget);	

		GPWidget.AttachWidgetToComponent(GroundPoundIconLocation);
		bWidgetIsVisible = true;
	}

	void HideWidget()
	{
		if(GPWidget == nullptr)
			return;

		bWidgetIsVisible = false;
		Game::GetMay().RemoveWidget(GPWidget);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnActorGroundPounded(AHazePlayerCharacter Player)
	{
		if(bAlreadyGroundPounded)
			return;

		ActorGroundPounded();
		
	}

	void ActorGroundPounded()
	{
		bAlreadyGroundPounded = true;
		HideWidget();
		MoveMesh();

	}

	UFUNCTION(BlueprintEvent)
	void MoveMesh()
	{

	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		PhysValue.SpringTowards(0.f, 35.f);
		PhysValue.Update(DeltaTime);

		PhysicsRoot.SetRelativeLocation(FVector(0.f, 0.f, PhysValue.Value));
	}

}