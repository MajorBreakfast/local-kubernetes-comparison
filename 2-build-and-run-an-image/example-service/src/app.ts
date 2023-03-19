import Fastify from 'fastify'

const server = Fastify()

server.get('/', async (_request, _reply) => {
  return 'Hello!'
})

const url = await server.listen({ port: 3000, host: '0.0.0.0' })
console.log(`Listening on ${url}`)
