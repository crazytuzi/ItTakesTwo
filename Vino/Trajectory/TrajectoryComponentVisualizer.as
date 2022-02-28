import Vino.Trajectory.TrajectoryComponent;
import Vino.Trajectory.TrajectoryStatics;

class UTrajectoryComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UTrajectoryComponent::StaticClass();

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent AnimationCompressionFormat)
    {
        UTrajectoryComponent Component = Cast<UTrajectoryComponent>(Component);
        if (Component == nullptr)
            return;

		FVector UpVector = Component.Owner.ActorUpVector;
        FVector Loc = Component.GetWorldLocation();
		const float GravityMagnitude = Component.Gravity;
		float Resolution = Component.VisualizeResolution;
		FVector Velocity = Component.Velocity;
		FTransform CompTransform = Component.GetWorldTransform();

		if (Component.TrajectoryMethod == ETrajectoryMethod::Calculation)
		{
			// Calculation means we're getting the velocity based on hitting a target position
			// So, lets calculate!
			float Height = Math::ConstrainVectorToDirection(Component.LocalTargetHeight, UpVector).Size();
			FVector Target = Component.LocalTargetPosition;
			FVector TargetWorld = CompTransform.TransformPosition(Target);

			Velocity = CalculateVelocityForPathWithHeight(Loc, TargetWorld, GravityMagnitude, Height, Component.TerminalSpeed, UpVector);

			// Set the TargetHeight vector to be positioned at the peak of the
			// parabola
			float PeakDistance = Math::ConstrainVectorToDirection(Velocity, UpVector).Size() / GravityMagnitude;
			FVector VelocityForward = Velocity;

			FVector LocalForward = CompTransform.InverseTransformVector(VelocityForward);
			LocalForward = Math::ConstrainVectorToPlane(LocalForward, UpVector);
			Component.LocalTargetHeight = LocalForward * PeakDistance + (UpVector * Height);
		}
		else if (!Component.bWorldSpace)
		{
			// Local-space, transform velocity vector
			Velocity = Component.GetWorldRotation().RotateVector(Velocity);
		}

		// Get points
		FTrajectoryPoints VisPoints = CalculateTrajectory(Loc, Component.VisualizeLength, Velocity, GravityMagnitude, Resolution, Component.TerminalSpeed, UpVector); 

		// Draw an arrow to show forward
		DrawArrow(Loc, Loc + Component.GetForwardVector() * 100.f, FLinearColor::Red);

		// Draw lines and stars!
		for(int i=0; i<VisPoints.Num(); ++i)
		{
			FVector Position = VisPoints.Positions[i];

			DrawWireStar(Position, 20.f ,FLinearColor::Red);
			DrawLine(Position, Position + VisPoints.Tangents[i] * 60.f, FLinearColor::Blue);

			// If this is the last point, we cant draw a line to the next one
			if (i < VisPoints.Num() - 1)
			{
				FVector NextPosition = VisPoints.Positions[i + 1];
				DrawLine(Position, NextPosition, FLinearColor::Green, 5.f);
			}
		}

    }
}