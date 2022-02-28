import Cake.LevelSpecific.SnowGlobe.MagnetHockey.HockeyPuck;
import Cake.LevelSpecific.SnowGlobe.MagnetHockey.HockeyGoals;

event void FHockeyPlayerLeftGame(UInteractionComponent InteractComp, AHazePlayerCharacter Player);

class AHockeyPaddle : AHazeActor 
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USphereComponent SphereComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp2;

	UPROPERTY(DefaultComponent, Attach = Root)
	UInteractionComponent InteractComp;

	UPROPERTY(Category = "Setup")
	UHazeCapabilitySheet PaddleCapabilitySheet;

	UPROPERTY(Category = "Setup")
	AHockeyPuck HockeyPuck;

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MoveComp;

	UPROPERTY(Category = "Scoring")
	AHockeyGoals HockeyGoal;

	float Radius = 400.f;

	float MovementSpeed = 3200.f;
	
	FHockeyPlayerLeftGame OnHockeyPlayerLeftEvent;
	
	FVector PlayerInput;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InteractComp.OnActivated.AddUFunction(this, n"OnInteracted");
		AddCapabilitySheet(PaddleCapabilitySheet);
		MoveComp.Setup(SphereComp);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		// If puck if within range.
			// Mirror it's velocity
	}

	UFUNCTION()
	void OnInteracted(UInteractionComponent OurInteractComp, AHazePlayerCharacter Player)
	{
		if (Player == Game::May)
			HockeyGoal.HockeyGoalPlayerOwner = EHockeyGoalPlayerOwner::May;
		else 
			HockeyGoal.HockeyGoalPlayerOwner = EHockeyGoalPlayerOwner::Cody;

	}
}