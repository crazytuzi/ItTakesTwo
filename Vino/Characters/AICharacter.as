import Vino.Movement.Components.MovementComponent;
import Vino.AI.PerceptionClasses.HazeAIPerceptionHearing;
import Vino.AI.PerceptionClasses.HazeAIPerceptionVision;
import Vino.Movement.MovementSettings;

settings AICharacterDefaultMovementSettings for UMovementSettings
{
	AICharacterDefaultMovementSettings.MoveSpeed = 600.f;
}

//This is an example character only. If you want to implement your own base them on either AIActorBase or AICharacterBase.
class AAICharacter : AHazeCharacter
{
	UPROPERTY(DefaultComponent)
	UHazeMovementComponent AIMovementComponent;
	default AIMovementComponent.DefaultMovementSettings = AICharacterDefaultMovementSettings;
	default AIMovementComponent.ControlSideDefaultCollisionSolver = n"AICharacterSolver";
	default AIMovementComponent.RemoteSideDefaultCollisionSolver = n"AICharacterRemoteCollisionSolver";
	
	UPROPERTY(DefaultComponent)
	UHazeCrumbComponent CrumbComponent;

	UPROPERTY(DefaultComponent)
	UHazePerceptionComponent PerceptionComponent;

	default CapsuleComponent.SetCollisionProfileName(n"PlayerCharacter");
	default CapsuleComponent.CanCharacterStepUpOn = ECanBeCharacterBase::ECB_No;
	FCollisionProfileName Deactivated;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		//PerceptionComponent
		SetupPerceptionComponent();
    }

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{	
		AIMovementComponent.Setup(CapsuleComponent);

		// //Movement
		AddCapability(n"CharacterFloorMoveCapability");
		AddCapability(n"CharacterFaceDirectionCapability");
		AddCapability(n"MovementDirectionInputCapability");
		AddCapability(n"CharacterDefaultMoveToCapability");
		
		//Collision
		AddCapability(n"AICollisionEnableCapability");

		if(Network::IsNetworked() && Game::IsEditorBuild())
		{
			AddDebugCapability(n"AISkeletalMeshNetworkVisualizationCapability");
		}

		//Enable Component and Set Sensing Interval.
		PerceptionComponent.SetComponentEnabled(true);
		PerceptionComponent.SetSensingInterval(0.2f);
	}

	UFUNCTION()
	void SetupPerceptionComponent()
	{
		PerceptionComponent.PerceptionClasses.Empty();

		//Create Perception Classes.
		UHazeAIPerceptionHearing HearingClass = Cast<UHazeAIPerceptionHearing>(NewObject(this, UHazeAIPerceptionHearing::StaticClass()));
		UHazeAIPerceptionVision VisionClass = Cast<UHazeAIPerceptionVision>(NewObject(this, UHazeAIPerceptionVision::StaticClass()));

		HearingClass.SetOwner(Cast<AHazeActor>(this));
		VisionClass.SetOwner(Cast<AHazeActor>(this));
		
		//Set DetectionValues
		VisionClass.DetectionRadius = 500.f;
		VisionClass.NoticedRadius = 1000.f;

		//Add Perception Classes to Component.
		PerceptionComponent.PerceptionClasses.AddUnique(HearingClass);
		PerceptionComponent.PerceptionClasses.AddUnique(VisionClass);
	}
};
