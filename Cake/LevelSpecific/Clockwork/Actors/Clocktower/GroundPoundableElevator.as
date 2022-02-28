import Vino.Movement.Components.GroundPound.GroundpoundedCallbackComponent;

class AGroundPoundableElevator : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent ElevatorMesh;

	UPROPERTY(DefaultComponent, Attach = ElevatorMesh)
	UStaticMeshComponent GroundPoundSign;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// FActorGroundPoundedDelegate OnGroundPound;
		// OnGroundPound.BindUFunction(this, n"OnActorGroundPounded");
		// BindOnActorGroundPounded(this, OnGroundPound);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnActorGroundPounded(AHazePlayerCharacter Player)
	{
		StartElevator();
		
	}

	UFUNCTION(BlueprintEvent)
	void StartElevator()
	{

	}


}