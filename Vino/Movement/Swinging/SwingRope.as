import Vino.Movement.Swinging.SwingRopeCableComponent;
import Vino.Movement.Swinging.SwingPointComponent;

class ASwingRope : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USwingRopeCableComponent RopeComp;

	bool RopeIsActive() const
	{
		return RopeComp.IsVisible();
	}

	void AttachToSwingPoint(USwingPointComponent SwingPoint)
	{
		if (SwingPoint == nullptr)
			return;

		RopeComp.AttachToSwingPoint(SwingPoint);
	}

	void DetachFromSwingPoint()
	{
		RopeComp.DetachFromSwingPoint();
	}
}

