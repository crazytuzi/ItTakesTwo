namespace Sap
{
	const float Radius = 35.f;

	namespace Shooting
	{
		const float FireRate = 12.f;
		const float SpreadRadius = 40.f;
		const float Lobbing = 200.f;
		const float ForceMinScale = 0.2f;
	}

	namespace Aim
	{
		const float MinTraceDistance = 500.f;
		const float MaxTraceDistance = 8300.f;
		const float SwarmSearchRadius = 500.f;
		const float WidgetMaxDistance = 4000.f;
	}

	namespace Pressure
	{
		const float Max = 10.f;
		const float RegenPause = 0.2f;
		const float RegenRate = 9.f;
		const float DecreaseRate = 1.5f;
	}

	namespace Predict
	{
	}

	namespace Projectile
	{
		const float Gravity = 2700.f;
		const float MaxFlyTime = 5.f;
		const float Mass = 1.f;
		const float MaxErrorReductionDistance = 5000.f;
		const float MaxErrorReductionRate = 2000.f;
	}

	namespace Batch
	{
		//const float MassLossRate = 0.09f;
		const float MassLossRate = 0.f;
		const float MinMass = 0.8f;

		const float NumBatches = 80;
		const float MinAvailableBatches = 10;

		const float MaxMass = 10.f;
		const float MassLossPause = 5.f;

		const float ExplosionMinRadius = 400.f;
		const float ExplosionMaxRadius = 800.f;
		const int MaxPointLights = 4;
	}

	namespace Explode
	{
		const float MinRadius = 400.f;
		const float MaxRadius = 800.f;
		const float MinDelay = 0.05f;
		const float MaxDelay = 0.1f;
	}

	namespace Stream
	{
		const int NumParticles = 30;
		const float CollisionDelay = 0.2f;
	}
}