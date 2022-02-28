import Vino.Movement.Grinding.UserGrindComponent;

class UCharacterGrindingTransferComponent : UActorComponent
{
	FGrindSplineData EvaluationTarget;

	UFUNCTION(BlueprintOverride)
	void OnResetComponent(EComponentResetType ResetType)
	{
		EvaluationTarget.Reset();
	}

	FVector GetHeightOffsetedEvaluationWorldLocation() const property
	{
		return EvaluationTarget.HeightOffsetedWorldLocation;
	}

	FHazeSplineSystemPosition& GetEvaluationPosition() property
	{
		return EvaluationTarget.SystemPosition;
	}

	const FHazeSplineSystemPosition& GetEvaluationPosition() const property
	{
		return EvaluationTarget.SystemPosition;
	}

	bool IsEvalTargetValid() const
	{
		return EvaluationTarget.IsValid() && EvaluationTarget.SystemPosition.IsOnValidSpline();
	}
}
