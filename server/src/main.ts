import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.enableCors();

  // Prefix all routes with /api
  app.setGlobalPrefix('api');

  // Health check route for ALB
  const server = app.getHttpAdapter().getInstance();
  server.get('/api/health', (req, res) => {
    res.status(200).json({ status: 'ok' });
  });

  await app.listen(3001, '0.0.0.0');
}

bootstrap();
