import Vino.Interactions.InteractionComponent;
import Vino.ContextIcons.ContextWidget;
import Vino.ContextIcons.ContextStatics;

event void FClockJumpReached(AHazePlayerCharacter Player);

class AClockworkLastBossJumpToGrindInteraction : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent BoxCollision;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent JumpToLocation;

	UPROPERTY()
	AActor JumpToActor;

	UPROPERTY()
	FClockJumpReached OnClockJumpToReached;

	UPROPERTY()
	TSubclassOf<UContextWidget> GrindWidget; 

	bool bHasJumped = false;

	UContextWidget Widget;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BoxCollision.OnComponentBeginOverlap.AddUFunction(this, n"OnOverlap");
		JumpToLocation.WorldTransform = JumpToActor.ActorTransform;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
	
	}

	UFUNCTION()
    void OnOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
	UPrimitiveComponent OtherComponent, int OtherBodyIndex, 
	bool bFromSweep, const FHitResult&in Hit)
    {
        AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;
	
		if (Widget != nullptr)
			return;

		if (bHasJumped)
			return;

		Widget = CreateContextWidget(Player, GrindWidget, JumpToLocation);
		Player.SetCapabilityAttributeObject(n"ClockworkJumpToGrindActor", this);
		Player.SetCapabilityActionState(n"CanJumpToGrind", EHazeActionState::Active);
    }

	UFUNCTION()
	void StartJumpToLocation(AHazePlayerCharacter Player)
	{
		Player.SetCapabilityActionState(n"CanJumpToGrind", EHazeActionState::Inactive);
		Widget.RemoveContextWidget();
		bHasJumped = true;

		FHazeDestinationEvents DestinationEvents;
		DestinationEvents.OnDestinationReached.BindUFunction(this, n"JumpToReached");
		FHazeJumpToData JumpData;
		JumpData.Transform = JumpToLocation.WorldTransform;
		JumpTo::ActivateJumpTo(Player, JumpData, DestinationEvents);
	}

	UFUNCTION()
	void JumpToReached(AHazeActor Actor)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Actor);
		OnClockJumpToReached.Broadcast(Player);
	}
}


