import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.enableCors();

  // ✅ Add raw health check route for ALB
  const server = app.getHttpAdapter().getInstance();
  server.get('/health', (req, res) => {
    res.status(200).json({ status: 'ok' });
  });

  await app.listen(3001, '0.0.0.0');


}

bootstrap();
