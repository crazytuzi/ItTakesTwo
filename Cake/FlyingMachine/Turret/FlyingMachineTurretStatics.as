void GetPitchYawDeltas(FVector From, FVector To, FVector Up, float& OutYawDelta, float& OutPitchDelta)
{
	{
		// Get yaw by projecting from and to onto the up-plane, then getting the angle between them
		FVector HoriStart = From.ConstrainToPlane(Up);
		FVector HoriEnd = To.ConstrainToPlane(Up);
		HoriStart.Normalize();
		HoriEnd.Normalize();

		float AbsoluteYaw = FMath::Acos(HoriStart.DotProduct(HoriEnd));

		FVector CrossUp = HoriStart.CrossProduct(HoriEnd);
		AbsoluteYaw *= FMath::Sign(CrossUp.DotProduct(Up));

		OutYawDelta = FMath::RadiansToDegrees(AbsoluteYaw);
	}

	{
		// Get pitch of from and to, then just get the difference
		float FromPitch = FMath::Asin(From.DotProduct(Up));
		float ToPitch = FMath::Asin(To.DotProduct(Up));

		OutPitchDelta = FMath::RadiansToDegrees(ToPitch - FromPitch);
	}
}