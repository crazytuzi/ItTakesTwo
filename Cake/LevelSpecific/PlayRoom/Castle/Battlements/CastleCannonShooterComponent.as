import Cake.LevelSpecific.PlayRoom.Castle.Battlements.CastleCannon;
import Cake.LevelSpecific.PlayRoom.Castle.Battlements.CastleCannonTransition;

class UCastleCannonShooterComponent : UActorComponent
{
	ACastleCannon ActiveCannon;

	UPROPERTY()
	TArray<ACastleCannonTransition> CannonTransitions;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GetAllActorsOfClass(CannonTransitions);
	}

	TArray<FPossibleCannonTransition> GetPossibleTransitionsFromActiveCannon()
	{
		TArray<FPossibleCannonTransition> PossibleCannonTransitions;

		for (ACastleCannonTransition CannonTransition : CannonTransitions)
		{
			if (ActiveCannon == CannonTransition.BeginningTransition.Cannon)
			{
				FPossibleCannonTransition Transition;
				Transition.TransitionActor = CannonTransition;
				Transition.TransitionDirection = CannonTransition.BeginningTransition.TransitionDirection;

				PossibleCannonTransitions.Add(Transition);
			}
			
			if (ActiveCannon == CannonTransition.EndTransition.Cannon)
			{
				FPossibleCannonTransition Transition;
				Transition.TransitionActor = CannonTransition;
				Transition.TransitionDirection = CannonTransition.EndTransition.TransitionDirection;

				PossibleCannonTransitions.Add(Transition);
			}
		}

		return PossibleCannonTransitions;
	}	

	ACastleCannon GetCannonTargetFromTransition(ACastleCannonTransition CannonTransition, ACastleCannon OriginCannon)
	{
		if (CannonTransition.BeginningTransition.Cannon != OriginCannon && CannonTransition.EndTransition.Cannon != OriginCannon)
			return nullptr;

		if (CannonTransition.BeginningTransition.Cannon == OriginCannon)
			return CannonTransition.EndTransition.Cannon;
		else 
			return CannonTransition.BeginningTransition.Cannon;

	}
}