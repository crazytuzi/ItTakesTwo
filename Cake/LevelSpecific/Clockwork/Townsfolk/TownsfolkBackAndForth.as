import Cake.LevelSpecific.Clockwork.Townsfolk.TownsfolkActor;
import Peanuts.Triggers.ActorTrigger;

class ATownsfolkBackAndForth : ATownsfolkActor
{
	UPROPERTY()
	float StopAtEnd = 3.f;

	UPROPERTY()
	float StopAtStart = 3.f;

	UPROPERTY()
	AActorTrigger DoorTrigger;

	UPROPERTY()
	UAnimSequence EndAnimation;

	default bAlwaysFaceMovementDirection = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		OnReachedEndOfSpline.AddUFunction(this, n"ReachedEndOfSpline");

		if (DoorTrigger != nullptr)
		{
			DoorTrigger.OnActorEnter.AddUFunction(this, n"EnterDoorTrigger");
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void ReachedEndOfSpline(ATownsfolkActor Townsfolk)
	{
		if (SplineFollow.Position.IsForwardOnSpline())
		{
			if (StopAtEnd >= 0.f)
			{
				System::SetTimer(this, n"ChangeDirection", StopAtEnd, false);
				if (EndAnimation != nullptr)
					PlayEventAnimation(Animation = EndAnimation);
			}
		}
		else
		{
			if (StopAtStart >= 0.f)
				System::SetTimer(this, n"ChangeDirection", StopAtStart, false);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void ChangeDirection()
	{
		SplineFollow.Reverse();
	}

	UFUNCTION(NotBlueprintCallable)
	void EnterDoorTrigger(AHazeActor Actor)
	{
		BP_EnterDoorTrigger();
	}

	UFUNCTION(BlueprintEvent)
	void BP_EnterDoorTrigger() {}
}