namespace SplineStatics 
{
	UHazeSplineComponentBase GetRandom(const TArray<UHazeSplineComponentBase>& Splines)
	{
		if (Splines.Num() == 0)
			return nullptr;

		int i = FMath::RandRange(0, Splines.Num() - 1);
		return Splines[i];
	}

	UHazeSplineComponentBase GetRandomInView(const TArray<UHazeSplineComponentBase>& Splines, float SplineFraction)
	{
		AHazePlayerCharacter Cody = Game::GetCody();
		AHazePlayerCharacter May = Game::GetMay();
		if ((Cody != nullptr) && (May != nullptr))
		{
			// Get random spline with the point at given fraction along spline in any players view
			TArray<UHazeSplineComponentBase> OnScreenSplines;
			for (UHazeSplineComponentBase Spline : Splines)
			{
				float Dist = Spline.SplineLength * SplineFraction;
				FVector Loc = Spline.GetLocationAtDistanceAlongSpline(Dist, ESplineCoordinateSpace::World);
				if (SceneView::IsInView(Cody, Loc) || SceneView::IsInView(May, Loc))
					OnScreenSplines.Add(Spline);
			}
			if (OnScreenSplines.Num() > 0)
				return GetRandom(OnScreenSplines);
		}
		return nullptr;
	}	
}

struct FSplinesContainer
{
	TArray<UHazeSplineComponentBase> Splines;
	private TArray<UHazeSplineComponentBase> UnusedSplines;
	private UHazeSplineComponentBase LastUsedSpline = nullptr;

	void UpdateUsedSplines()
	{
		if (UnusedSplines.Num() == 0)
		{
			UnusedSplines = Splines; 
			if (UnusedSplines.Num() > 1)
				UnusedSplines.Remove(LastUsedSpline);
		}
	}
	void MarkSplineUsed(UHazeSplineComponentBase Spline)
	{
		UnusedSplines.Remove(Spline);
		LastUsedSpline = Spline;
	}

	UHazeSplineComponentBase UseBestSpline(float SplineFraction)
	{
		UpdateUsedSplines();
		UHazeSplineComponentBase Spline = SplineStatics::GetRandomInView(UnusedSplines, SplineFraction);
		if (Spline == nullptr)
			Spline = SplineStatics::GetRandom(UnusedSplines);
		MarkSplineUsed(Spline);
		return Spline;
	}	

	UHazeSplineComponentBase UseRandomSpline()
	{
		UpdateUsedSplines();
		UHazeSplineComponentBase Spline = SplineStatics::GetRandom(UnusedSplines);
		MarkSplineUsed(Spline);
		return Spline;
	}
}


