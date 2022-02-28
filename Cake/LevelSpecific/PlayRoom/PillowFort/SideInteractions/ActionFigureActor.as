import Vino.Interactions.InteractionComponent;
import Vino.Movement.Components.GroundPound.GroundpoundedCallbackComponent;
import Vino.Buttons.GroundPoundButton;


class AActionFigureActor : AHazeActor
{
	//Ground pounded > Start Delay Timer (Net verify?) > Play Random Event.
		// IF Both buttons pressed in Start delay > Play First Dialogue Event.
			//Keep Repeating if done 3 times then no more and unlock achievement.

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	//default SetActorTickEnabled(false);

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSkeletalMeshComponentBase ActionFigureMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	UCapsuleComponent CapsuleComp;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent AkComp;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 5500.f;

	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{

	}
}