import Vino.Movement.SplineSlide.SplineSlideSpline;
import Vino.Movement.SplineSlide.SplineSlideComponent;

UFUNCTION()
void StartSplineSlide(AHazePlayerCharacter Player, ASplineSlideSpline SplineSlideSpline)
{
	if (Player == nullptr)
		return;

	if (SplineSlideSpline == nullptr)
		return;
		
	USplineSlideComponent SlidingComp = USplineSlideComponent::GetOrCreate(Player);
	SlidingComp.ActiveSplineSlideSpline = SplineSlideSpline;
}

UFUNCTION()
void StopSplineSlide(AHazePlayerCharacter Player)
{
	if (Player == nullptr)
		return;
		
	USplineSlideComponent SlidingComp = USplineSlideComponent::GetOrCreate(Player);
	SlidingComp.ActiveSplineSlideSpline = nullptr;
}